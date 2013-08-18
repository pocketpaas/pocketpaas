package App::PocketPaas::Command::info;
use App::PocketPaas -command;

# ABSTRACT: info about a single application

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;

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

    my $status = {};

    if ( my $latest_image = @{ $app->images() }[0] ) {
        $status->{latest_build} = $latest_image->tag();
    }
    $status->{builds} = [ map { $_->tag() } @{ $app->images() } ];

    if ( my ($running_container)
        = grep { $_->status() eq 'running' } @{ $app->containers() } )
    {
        $status->{state}         = 'running';
        $status->{running_build} = $running_container->tag();
    }
    else {
        $status->{state} = 'stopped';
    }

    my $note = App::PocketPaas::Notes->get_note("app_$app_name");
    $status->{services} = $note->{services};

    print Dump($status);
}

1;
