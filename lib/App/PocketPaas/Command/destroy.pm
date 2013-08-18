package App::PocketPaas::Command::destroy;
use App::PocketPaas -command;

# ABSTRACT: delete the current application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;
use App::PocketPaas::Util;
use App::PocketPaas::Notes;

use Cwd;
use Log::Log4perl qw(:easy);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
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

    INFO("Destroying $app_name");

    # TODO: check for running services and
    # stop/destroy them, with confirmation

    if ($app) {
        INFO("Stopping running containers");
        foreach my $container ( @{ $app->containers() } ) {
            if ( $container->status() eq 'running' ) {
                App::PocketPaas::Docker->stop( $container->docker_id() );
            }
            App::PocketPaas::Docker->rm( $container->docker_id() );
        }

        foreach my $image ( @{ $app->images() } ) {
            App::PocketPaas::Docker->rmi(
                "pocketpaas/$app_name:" . $image->build_tag() );
            App::PocketPaas::Docker->rmi(
                "pocketpaas/$app_name:" . $image->run_tag() );
        }

        App::PocketPaas::Notes->delete_note("app_$app_name");
    }
    else {
        ERROR("No app by the name of $app_name");
        return;
    }

}

1;
