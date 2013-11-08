package App::PocketPaas::Command::destroy;
use base qw(App::PocketPaas::Command);

# ABSTRACT: delete the current application

use strict;
use warnings;

use App::PocketPaas::App qw(load_app);
use App::PocketPaas::Core;
use App::PocketPaas::Task::DestroyApp;
use App::PocketPaas::Util qw(load_app_config);

use Cwd;
use Log::Log4perl qw(:easy);

sub options {
    return (
        [ "name|n=s", "application name, defaults to the directory name or read from pps.yml" ], );
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

    # TODO add confirmation

    INFO("Destroying $app_name");

    $pps->queue_task( App::PocketPaas::Task::DestroyApp->new( $pps, $app_config, $app ) );

    $pps->finish_queue();
}

1;
