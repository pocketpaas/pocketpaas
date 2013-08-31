package App::PocketPaas::App;

use strict;
use warnings;

use App::PocketPaas::Docker qw(
    docker_attach docker_build docker_commit docker_containers docker_images
    docker_rm docker_rmi docker_run docker_stop docker_wait
);
use App::PocketPaas::Hipache qw(add_hipache_app);
use App::PocketPaas::Model::App;
use App::PocketPaas::Notes qw(add_note delete_note);
use App::PocketPaas::Util qw(next_tag);

use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use IPC::Run3;
use Log::Log4perl qw(:easy);

use Sub::Exporter -setup =>
    { exports => [qw(push_app start_app stop_app destroy_app)] };

sub push_app {
    my ( $config, $app_config ) = @_;

    my $app_name = $app_config->{name};

    my $app = App::PocketPaas::Model::App->load(
        $app_name,
        docker_containers( $config, { all => 1 } ),
        docker_images( $config, )
    );

    INFO("Pushing $app_name");

    my $app_build_dir = tempdir();

    DEBUG("App build dir: $app_build_dir");

    _generate_app_tarball($app_build_dir);

    prepare_app_build( $app_build_dir, $app_name );

    my $tag = next_tag( $config, $app );

    if (docker_build(
            $config, $app_build_dir, "pocketapp/$app_name:temp-$tag"
        )
        )
    {
        INFO("Application built successfully");
    }
    else {
        docker_rmi( $config, "pocketapp/$app_name:temp-$tag" );
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
    if (my $build_container_id = docker_run(
            $config,
            "pocketapp/$app_name:temp-$tag",
            {   daemon  => 1,
                command => '/build/builder',
                %cache_volume_opts
            }
        )
        )
    {
        INFO("App build container: $build_container_id");
        docker_attach( $config, $build_container_id );

        if ( docker_wait( $config, $build_container_id ) ) {
            docker_commit( $config, $build_container_id,
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

    start_app( $config, $app_config, $tag, $app );

    docker_rmi( $config, "pocketapp/$app_name:temp-$tag" );

}

sub start_app {
    my ( $config, $app_config, $tag, $app ) = @_;

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

    if (!docker_build(
            $config, $app_run_build_dir, "pocketapp/$app_name:run-$tag"
        )
        )
    {
        return;
    }

    # now start it up (-:
    INFO("Starting application");
    my $docker_id
        = docker_run( $config, "pocketapp/$app_name:run-$tag",
        { daemon => 1 } );

    if ( !$docker_id ) {
        return;
    }

    # add to hipache
    add_hipache_app( $config, $app_config, $docker_id );

    add_note(
        $config,
        "app_$app_name",
        {   services  => $service_names,
            name      => $app_name,
            should_be => 'running',
        }
    );

    # if app was previously running
    if ($app) {
        INFO("Stopping previous containers");
        foreach my $container ( @{ $app->containers() } ) {
            if ( $container->status() eq 'running' ) {
                docker_stop( $config, $container->docker_id() );
            }
            docker_rm( $config, $container->docker_id() );
        }
    }

    # TODO remove previous "run" tag, if it exists

    # TODO record which build was used so that the same
    # one can be used in recovery.
}

sub stop_app {
    my ( $config, $app_config, $app ) = @_;

    my $app_name = $app_config->{name};

    INFO("Stopping running containers");
    foreach my $container ( @{ $app->containers() } ) {
        if ( $container->status() eq 'running' ) {
            docker_stop( $config, $container->docker_id() );
        }
    }

    # TODO update should_be in app note
}

sub destroy_app {
    my ( $config, $app_config, $app ) = @_;

    my $app_name = $app_config->{name};

    INFO("Stopping running containers");
    foreach my $container ( @{ $app->containers() } ) {
        if ( $container->status() eq 'running' ) {
            docker_stop( $config, $container->docker_id() );
        }
        docker_rm( $config, $container->docker_id() );
    }

    foreach my $image ( @{ $app->images() } ) {
        docker_rmi( $config, "pocketapp/$app_name:" . $image->build_tag() );
        docker_rmi( $config, "pocketapp/$app_name:" . $image->run_tag() );
    }

    delete_note( $config, "app_$app_name" );
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
