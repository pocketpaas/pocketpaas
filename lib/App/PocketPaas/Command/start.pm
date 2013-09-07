package App::PocketPaas::Command::start;
use App::PocketPaas -command;

# ABSTRACT: start an application

use strict;
use warnings;

use App::PocketPaas::App qw(load_app);
use App::PocketPaas::Core;
use App::PocketPaas::Task::StartApp;
use App::PocketPaas::Util qw(load_app_config);

use Cwd;
use Log::Log4perl qw(:easy);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
        [ "build|b=s", "build to start, defaults to latest build" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $pps = App::PocketPaas::Core->load_pps();

    my $app_config = load_app_config( $pps->config, getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    my $app = load_app( $pps->config, $app_name );

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    INFO("Starting $app_name");

    $pps->queue_task(
        App::PocketPaas::Task::StartApp->new(
            $pps, $app_name, $app_config->{services},
            $opt->{build}, $app
        )
    );

    $pps->finish_queue();
}

1;
