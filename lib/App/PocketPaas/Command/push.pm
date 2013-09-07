package App::PocketPaas::Command::push;
use App::PocketPaas -command;

# ABSTRACT: build the current application

use strict;
use warnings;

use App::PocketPaas::Core;
use App::PocketPaas::Task::PushApp;
use App::PocketPaas::Util qw(load_app_config);

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

    my $pps = App::PocketPaas::Core->load_pps();

    my $app_config = load_app_config( $pps->config, getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    $pps->queue_task(
        App::PocketPaas::Task::PushApp->new( $pps, $app_config ) );

    $pps->finish_queue();
}

1;
