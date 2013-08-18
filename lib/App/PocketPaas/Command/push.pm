package App::PocketPaas::Command::push;
use App::PocketPaas -command;

# ABSTRACT: build the current application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Service;
use App::PocketPaas::Model::App;
use App::PocketPaas::Util;

use Cwd;
use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use IPC::Run3;
use Log::Log4perl qw(:easy);
use File::Path qw(make_path);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
        [   "stage|s",
            "run new code in a new container without replacing production"
        ],
        [ "no-cache",    "build without using a cache" ],
        [ "reset-cache", "reset the build cache" ],
        [ "service=s@",  "bind services to the application" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $app_config = App::PocketPaas::Util->load_app_config( getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    my $app = App::PocketPaas::Model::App->load(
        $app_name,
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images()
    );

    INFO("Pushing $app_name");

    my $app_build_dir = tempdir();

    DEBUG("App build dir: $app_build_dir");

    generate_app_tarball($app_build_dir);
    prepare_app_build( $app_build_dir, $app_name );

    my $tag = App::PocketPaas::Util::next_tag($app);

    if (App::PocketPaas::Docker->build(
            $app_build_dir, "pocketpaas/$app_name:temp-$tag"
        )
        )
    {
        INFO("Application built successfully");
    }
    else {
        App::PocketPaas::Docker->rmi("pocketpaas/$app_name:temp-$tag");
        return;
    }

    my $app_run_build_dir = tempdir();
    DEBUG("Run build dir: $app_run_build_dir");

    my %cache_volume_opts;
    if ( !$opt->{'no_cache'} ) {
        my $cache_dir = "$ENV{HOME}/.pocketpaas/cache/$app_name";
        if ( $opt->{'reset_cache'} ) {

            # TODO: remove cache path, might be root owned
        }
        make_path($cache_dir);

        %cache_volume_opts = ( volumes => ["$cache_dir:/cache"] );
    }

    INFO("Building application");
    if (my $build_container_id = App::PocketPaas::Docker->run(
            "pocketpaas/$app_name:temp-$tag",
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
                "pocketpaas/$app_name", "build-$tag" );
        }
        else {
            # TODO: clean up images
            FATAL("Application build failed");
        }
    }
    else {
        return;
    }

    my $service_env = '';
    if ( $app_config->{services} ) {
        foreach my $service ( @{ $app_config->{services} } ) {
            my $name = $service->{name};
            my $type = $service->{type};

            # TODO add support for a git url as the type
            $service_env
                = App::PocketPaas::Service->provision_service( $name, $type );
        }
    }

    prepare_run_build( $app_run_build_dir, $app_name, $tag, $service_env );

    if (!App::PocketPaas::Docker->build(
            $app_run_build_dir, "pocketpaas/$app_name:run-$tag"
        )
        )
    {
        return;
    }

    # TODO create run image with environment, including
    # any services

    # now start it up (-:
    INFO("Starting application");
    if (!App::PocketPaas::Docker->run(
            "pocketpaas/$app_name:run-$tag",
            { daemon => 1 }
        )
        )
    {
        return;
    }

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

    App::PocketPaas::Docker->rmi("pocketpaas/$app_name:temp-$tag");
}

sub generate_app_tarball {
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
from    pocketpaas/$app_name:build-$tag
env     PORT 5000
env     POCKETPAAS true
$service_env
expose  5000
cmd     ["/start", "web"]
DOCKER2
}

1;
