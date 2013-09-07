package App::PocketPaas::Command::setup;
use App::PocketPaas -command;

# ABSTRACT: setup pocketpaas

use strict;
use warnings;

use App::PocketPaas::Core;

use Log::Log4perl qw(:easy);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $pps = App::PocketPaas::Core->load_pps();

    INFO("PocketPaas setup complete.");
}

1;
