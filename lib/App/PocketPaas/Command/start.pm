package App::PocketPaas::Command::start;
use App::PocketPaas -command;

# ABSTRACT: start an application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Util;
use App::PocketPaas::Model::App;

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

    my $app_config = App::PocketPaas::Util->load_app_config( getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    # TODO check for application already running

    my $app = App::PocketPaas::Model::App->load(
        $app_name,
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images()
    );

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    my $build = $opt->{build};

    my $image;

    if ($build) {
        ($image) = grep { $_->tag() eq $build } @{ $app->images };
        if ( !$image ) {
            die "Unable to find image for build $build.\n";
        }
    }
    else {
        die "No images for app.\n" unless @{ $app->images };
        $image = @{ $app->images }[0];
    }

    # TODO create new run image with environment, including
    # any services

    App::PocketPaas::Docker->run( "pocketpaas/$app_name:" . $image->run_tag(),
        { daemon => 1 } );

    # TODO record which build was used so that the same
    # one can be used in recovery.
}

1;
