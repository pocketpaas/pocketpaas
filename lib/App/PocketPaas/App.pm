package App::PocketPaas::App;

use strict;
use warnings;

use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use IPC::Run3;
use Log::Log4perl qw(:easy);
use File::Path qw(make_path);

sub push_app {
    my ( $class, $app_config ) = @_;

    my $app_name = $app_config->{name};

    my $app = App::PocketPaas::Model::App->load(
        $app_name,
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images()
    );

    INFO("Pushing $app_name");

    my $app_build_dir = tempdir();

    DEBUG("App build dir: $app_build_dir");

    _generate_app_tarball($app_build_dir);

    prepare_app_build( $app_build_dir, $app_name );

    my $tag = App::PocketPaas::Util::next_tag($app);

    if (App::PocketPaas::Docker->build(
            $app_build_dir, "pocketapp/$app_name:temp-$tag"
        )
        )
    {
        INFO("Application built successfully");
    }
    else {
        App::PocketPaas::Docker->rmi("pocketapp/$app_name:temp-$tag");
        return;
    }

    my %cache_volume_opts;
    if ( !$app_config->{'no_cache'} ) {
        my $cache_dir = "$ENV{HOME}/.pocketpaas/cache/$app_name";
        if ( $app_config->{'reset_cache'} ) {

            # TODO: remove cache path, might be root owned
        }
        make_path($cache_dir);

        %cache_volume_opts = ( volumes => ["$cache_dir:/cache"] );
    }

    INFO("Building application");
    if (my $build_container_id = App::PocketPaas::Docker->run(
            "pocketapp/$app_name:temp-$tag",
            {   daemon  => 1,
                command => '/build/builder',
                %cache_volume_opts
            }
        )
        )
    {
        INFO("App build container: $build_container_id");
        App::PocketPaas::Docker->attach($build_container_id);

        if ( App::PocketPaas::Docker->wait($build_container_id) ) {
            App::PocketPaas::Docker->commit( $build_container_id,
                "pocketapp/$app_name", "build-$tag" );
        }
        else {
            # TODO: clean up images
            FATAL("Application build failed");
        }
    }
    else {
        return;
    }

    $class->start_app( $app_config, $tag, $app );

    App::PocketPaas::Docker->rmi("pocketapp/$app_name:temp-$tag");

}

sub start_app {
    my ( $class, $app_config, $tag, $app ) = @_;

    my $app_name = $app_config->{name};

    my $app_run_build_dir = tempdir();
    DEBUG("Run build dir: $app_run_build_dir");

    # TODO services are blank when not run from app dir,
    # perhaps record services in note
    my $service_env   = '';
    my $service_names = [];
    if ( $app_config->{services} ) {
        foreach my $service ( @{ $app_config->{services} } ) {
            my $name = $service->{name};
            my $type = $service->{type};

            # TODO add support for a git url as the type
            $service
                = App::PocketPaas::Service->provision_service( $name, $type );

            $service_env .= $service->env();

            push @$service_names, $name;
        }
    }

    prepare_run_build( $app_run_build_dir, $app_name, $tag, $service_env );

    if (!App::PocketPaas::Docker->build(
            $app_run_build_dir, "pocketapp/$app_name:run-$tag"
        )
        )
    {
        return;
    }

    # now start it up (-:
    INFO("Starting application");
    if (!App::PocketPaas::Docker->run(
            "pocketapp/$app_name:run-$tag",
            { daemon => 1 }
        )
        )
    {
        return;
    }

    App::PocketPaas::Notes->add_note(
        "app_$app_name",
        {   services  => $service_names,
            name      => $app_name,
            should_be => 'running',
        }
    );

    INFO("TODO: putting new application into hipache proxy");

    # if app was previously running
    if ($app) {
        INFO("Stopping previous containers");
        foreach my $container ( @{ $app->containers() } ) {
            if ( $container->status() eq 'running' ) {
                App::PocketPaas::Docker->stop( $container->docker_id() );
            }
            App::PocketPaas::Docker->rm( $container->docker_id() );
        }
    }

    # TODO remove previous "run" tag, if it exists

    # TODO record which build was used so that the same
    # one can be used in recovery.
}

sub stop_app {
    my ( $class, $app_config, $app ) = @_;

    my $app_name = $app_config->{name};

    INFO("Stopping running containers");
    foreach my $container ( @{ $app->containers() } ) {
        if ( $container->status() eq 'running' ) {
            App::PocketPaas::Docker->stop( $container->docker_id() );
        }
    }

    # TODO update should_be in app note
}

sub destroy_app {
    my ( $class, $app_config, $app ) = @_;

    my $app_name = $app_config->{name};

    INFO("Stopping running containers");
    foreach my $container ( @{ $app->containers() } ) {
        if ( $container->status() eq 'running' ) {
            App::PocketPaas::Docker->stop( $container->docker_id() );
        }
        App::PocketPaas::Docker->rm( $container->docker_id() );
    }

    foreach my $image ( @{ $app->images() } ) {
        App::PocketPaas::Docker->rmi(
            "pocketapp/$app_name:" . $image->build_tag() );
        App::PocketPaas::Docker->rmi(
            "pocketapp/$app_name:" . $image->run_tag() );
    }

    App::PocketPaas::Notes->delete_note("app_$app_name");
}

sub _generate_app_tarball {
    my $dest_dir = shift;

    INFO("Generating tarball for application");

    my @create_tar_cmd = (
        qw(git archive --format tar --prefix app/ -o),
        "$dest_dir/app.tar", qw(master)
    );

    run3 \@create_tar_cmd;
}

sub prepare_app_build {
    my ( $dest_dir, $app_name ) = @_;

    write_file( "$dest_dir/Dockerfile", <<DOCKER);
from    progrium/buildstep
add     app.tar /
DOCKER
}

sub prepare_run_build {
    my ( $app_run_build_dir, $app_name, $tag, $service_env ) = @_;

    # TODO fix this to allow '=' in values
    $service_env =~ s/^/ENV /gmsi;
    $service_env =~ s/=/ /gmsi;

    write_file( "$app_run_build_dir/Dockerfile", <<DOCKER2);
from    pocketapp/$app_name:build-$tag
env     PORT 5000
env     POCKETPAAS true
$service_env
expose  5000
cmd     ["/start", "web"]
DOCKER2
}

1;
