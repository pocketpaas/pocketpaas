package App::PocketPaas::Command::push;
use App::PocketPaas -command;

# ABSTRACT: build the current application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;
use App::PocketPaas::Model::Image;
use App::PocketPaas::Model::Container;

use DateTime;
use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use IPC::Run3;
use Log::Log4perl qw(:easy);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
        [   "stage|s",
            "run new code in a new container without replacing production"
        ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $app_name = $opt->{name} || 'testapp';

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

    my $tag = DateTime->now()->strftime('%F-%H-%M-%S');

    if (App::PocketPaas::Docker->build(
            $app_build_dir, "minipaas/$app_name:build-$tag"
        )
        )
    {
        INFO("Application built successfully");
    }
    else {
        return;
    }

    my $app_run_build_dir = tempdir();
    DEBUG("Run build dir: $app_run_build_dir");

    prepare_run_build( $app_run_build_dir, $app_name, $tag );

    if (!App::PocketPaas::Docker->build(
            $app_run_build_dir, "minipaas/$app_name:run-$tag"
        )
        )
    {
        return;
    }

    # now start it up (-:
    INFO("Starting application");
    if (!App::PocketPaas::Docker->run(
            "minipaas/$app_name:run-$tag", { daemon => 1 }
        )
        )
    {
        return;
    }

    INFO("TODO: putting new application into hipache proxy");

    INFO("Stopping previous containers");
    foreach my $container ( @{ $app->containers() } ) {
        if ( $container->status() eq 'running' ) {
            App::PocketPaas::Docker->stop( $container->docker_id() );
        }
        App::PocketPaas::Docker->rm( $container->docker_id() );
    }
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
run     /build/builder
DOCKER
}

sub prepare_run_build {
    my ( $app_run_build_dir, $app_name, $tag ) = @_;

    write_file( "$app_run_build_dir/Dockerfile", <<DOCKER2);
from    minipaas/$app_name:build-$tag
env     PORT 5000
expose  5000
cmd     ["/start", "web"]
DOCKER2
}

1;
