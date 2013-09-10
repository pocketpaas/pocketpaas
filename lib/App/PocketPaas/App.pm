package App::PocketPaas::App;

use strict;
use warnings;

use App::PocketPaas::Docker qw(
    docker_attach docker_build docker_commit docker_containers docker_images
    docker_rm docker_rmi docker_run docker_stop docker_wait
);
use App::PocketPaas::Hipache qw(add_hipache_app);
use App::PocketPaas::Model::App;
use App::PocketPaas::Notes qw(add_note delete_note query_notes);

use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use List::MoreUtils qw(any);
use IPC::Run3;
use Log::Log4perl qw(:easy);

use Sub::Exporter -setup => {
    exports => [
        qw(load_app load_app_names load_all_apps find_apps_using_service build_app start_app stop_app destroy_app)
    ]
};

sub load_app {
    my ( $config, $app_name ) = @_;

    return App::PocketPaas::Model::App->load( $config, $app_name,
        docker_containers( $config, { all => 1 } ),
        docker_images($config) );
}

sub load_app_names {
    my ($config) = @_;

    return App::PocketPaas::Model::App->load_names( $config,
        docker_containers( $config, { all => 1 } ),
        docker_images($config) );
}

sub load_all_apps {
    my ($config) = @_;

    return App::PocketPaas::Model::App->load_all( $config,
        docker_containers( $config, { all => 1 } ),
        docker_images($config) );
}

sub find_apps_using_service {
    my ( $config, $service_name ) = @_;

    my $app_notes = query_notes(
        $config,
        sub {
            my ( $key, $contents ) = @_;

            return 0 unless $key =~ /^app_/;
            return any { $_->{name} eq $service_name } @{ $contents->{services} };
        }
    );

    # TODO only count apps that are running (or should be running)
    #my $all_apps = load_all_apps($config);

    [ map { $_->{contents}{name} } @$app_notes ];
}

sub build_app {
    my ( $config, $app_name, $app_config, $tag, $app ) = @_;

    my $app_build_dir = tempdir();

    DEBUG("App build dir: $app_build_dir");

    _generate_app_tarball($app_build_dir);

    prepare_app_build( $config, $app_build_dir, $app_name );

    if (docker_build(
            $config, $app_build_dir, $config->{app_image_prefix} . "/$app_name:temp-$tag"
        )
        )
    {
        INFO("Application built successfully");
    }
    else {
        docker_rmi( $config, $config->{app_image_prefix} . "/$app_name:temp-$tag" );
        return;
    }

    my %cache_volume_opts;
    if ( !$app_config->{'no_cache'} ) {
        my $cache_dir = $config->{base_dir} . "/cache/$app_name";
        if ( $app_config->{'reset_cache'} ) {

            # TODO: remove cache path, might be root owned
        }
        make_path($cache_dir);

        %cache_volume_opts = ( volumes => ["$cache_dir:/cache"] );
    }

    INFO("Building application");
    if (my $build_container_id = docker_run(
            $config,
            $config->{app_image_prefix} . "/$app_name:temp-$tag",
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
                $config->{app_image_prefix} . "/$app_name", "build-$tag" );
        }
        else {
            # TODO: clean up images
            FATAL("Application build failed");
        }
    }
    else {
        return;
    }

}

sub start_app {
    my ( $config, $app_name, $tag, $app, $service_env ) = @_;

    my $app_run_build_dir = tempdir();
    DEBUG("Run build dir: $app_run_build_dir");

    prepare_run_build( $config, $app_run_build_dir, $app_name, $tag, $service_env );

    if (!docker_build(
            $config, $app_run_build_dir, $config->{app_image_prefix} . "/$app_name:run-$tag"
        )
        )
    {
        return;
    }

    docker_rmi( $config, $config->{app_image_prefix} . "/$app_name:temp-$tag" );

    # now start it up (-:
    INFO("Starting application");
    my $docker_id = docker_run( $config, $config->{app_image_prefix} . "/$app_name:run-$tag",
        { daemon => 1 } );

    if ( !$docker_id ) {
        return;
    }

    # add to hipache
    add_hipache_app( $config, $app_name, $docker_id );

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
        docker_rmi( $config, "$config->{app_image_prefix}/$app_name:" . $image->build_tag() );
        docker_rmi( $config, "$config->{app_image_prefix}/$app_name:" . $image->run_tag() );
    }

    delete_note( $config, "app_$app_name" );
}

sub _generate_app_tarball {
    my $dest_dir = shift;

    INFO("Generating tarball for application");

    my @create_tar_cmd
        = ( qw(git archive --format tar --prefix app/ -o), "$dest_dir/app.tar", qw(master) );

    run3 \@create_tar_cmd;
}

sub prepare_app_build {
    my ( $config, $dest_dir, $app_name ) = @_;

    write_file( "$dest_dir/Dockerfile", <<DOCKER);
from    progrium/buildstep
add     app.tar /
DOCKER
}

sub prepare_run_build {
    my ( $config, $app_run_build_dir, $app_name, $tag, $service_env ) = @_;

    if ($service_env) {

        # TODO fix this to allow '=' in values
        $service_env =~ s/^/ENV /gmsi;
        $service_env =~ s/=/ /gmsi;
    }

    write_file( "$app_run_build_dir/Dockerfile", <<DOCKER2);
from    $config->{app_image_prefix}/$app_name:build-$tag
env     PORT 5000
env     POCKETPAAS true
$service_env
expose  5000
cmd     ["/start", "web"]
DOCKER2
}

1;
