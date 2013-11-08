package App::PocketPaas::Command::setup;
use base qw(App::PocketPaas::Command);

# ABSTRACT: setup pocketpaas

use strict;
use warnings;

use App::PocketPaas::Core;

use Log::Log4perl qw(:easy);

sub options {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $pps = App::PocketPaas::Core->load_pps();

    INFO("PocketPaas setup complete.");
}

1;
