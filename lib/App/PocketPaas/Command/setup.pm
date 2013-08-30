package App::PocketPaas::Command::setup;
use App::PocketPaas -command;

# ABSTRACT: setup pocketpaas

use strict;
use warnings;

use App::PocketPaas::Core qw(setup_pocketpaas);
use App::PocketPaas::Config qw(get_config);

use Log::Log4perl qw(:easy);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $config = get_config();
    setup_pocketpaas($config);

    INFO("PocketPaas setup complete.");

}

1;
