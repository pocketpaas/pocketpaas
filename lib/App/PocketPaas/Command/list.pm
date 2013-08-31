package App::PocketPaas::Command::list;
use App::PocketPaas -command;

# ABSTRACT: list applications

use strict;
use warnings;

use App::PocketPaas::Core qw(setup_pocketpaas);
use App::PocketPaas::Config qw(get_config);
use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;

use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $config = get_config();
    setup_pocketpaas($config);

    my $app_names
        = App::PocketPaas::Model::App->load_names(
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images() );

    print Dump($app_names);
}

1;
