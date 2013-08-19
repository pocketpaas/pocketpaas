package App::PocketPaas::Command::list;
use App::PocketPaas -command;

# ABSTRACT: list applications

use strict;
use warnings;

use App::PocketPaas;
use App::PocketPaas::Docker;
use App::PocketPaas::Model::App;

use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::PocketPaas->setup();

    my $app_names
        = App::PocketPaas::Model::App->load_names(
        App::PocketPaas::Docker->containers( { all => 1 } ),
        App::PocketPaas::Docker->images() );

    print Dump($app_names);
}

1;
