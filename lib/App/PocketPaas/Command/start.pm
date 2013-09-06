package App::PocketPaas::Command::start;
use App::PocketPaas -command;

# ABSTRACT: start an application

use strict;
use warnings;

use App::PocketPaas::Core qw(setup_pocketpaas);
use App::PocketPaas::Config qw(get_config);
use App::PocketPaas::App qw(start_app load_app);
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

    my $config = get_config();
    setup_pocketpaas($config);

    my $app_config = load_app_config( $config, getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    my $app = load_app( $config, $app_name );

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    INFO("Starting $app_name");

    # TODO check for application already running

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

    start_app( $config, $app_config, $image->tag(), $app );
}

1;
