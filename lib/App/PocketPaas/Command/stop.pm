package App::PocketPaas::Command::stop;
use App::PocketPaas -command;

# ABSTRACT: stop an application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;

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

    my $app_name = $opt->{name}
        || die "Please provide an application name with --name\n";

    my $app = App::PocketPaas::Model::App->load(
        $app_name,
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images()
    );

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    if ($app) {
        INFO("Stopping running containers");
        foreach my $container ( @{ $app->containers() } ) {
            if ( $container->status() eq 'running' ) {
                App::PocketPaas::Docker->stop( $container->docker_id() );
            }
        }
    }
    else {
        ERROR("No app by the name of $app_name");
        return;
    }

}

1;
