package App::PocketPaas::Command::setup;
use App::PocketPaas -command;

# ABSTRACT: setup pocketpaas

use strict;
use warnings;

use App::PocketPaas;

use Log::Log4perl qw(:easy);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::PocketPaas->setup();

    INFO("PocketPaas setup complete.");

}

1;
