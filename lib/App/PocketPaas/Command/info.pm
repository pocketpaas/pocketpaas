package App::PocketPaas::Command::info;
use App::PocketPaas -command;

# ABSTRACT: info about a single application

use strict;
use warnings;

use App::PocketPaas::Core;
use App::PocketPaas::Notes qw(get_note);
use App::PocketPaas::App qw(load_app);
use App::PocketPaas::Util qw(load_app_config);

use Cwd;
use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
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

    my $status = {};

    if ( my $latest_image = @{ $app->images() }[0] ) {
        $status->{latest_build} = $latest_image->tag();
    }
    $status->{builds} = [ map { $_->tag() } @{ $app->images() } ];

    if ( my ($running_container)
        = grep { $_->status() eq 'running' } @{ $app->containers() } )
    {
        $status->{running_build} = $running_container->tag();
    }
    else {
    }
    $status->{status} = $app->status();

    my $note = get_note( $pps->config, "app_$app_name" );
    $status->{services} = $note->{services};

    print Dump($status);
}

1;
