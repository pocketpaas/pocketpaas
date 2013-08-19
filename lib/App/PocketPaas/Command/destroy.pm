package App::PocketPaas::Command::destroy;
use App::PocketPaas -command;

# ABSTRACT: delete the current application

use strict;
use warnings;

use App::PocketPaas::App;
use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;
use App::PocketPaas::Util;

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

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    # TODO add confirmation

    INFO("Destroying $app_name");

    App::PocketPaas::App->destroy_app( $app_config, $app );
}

1;
