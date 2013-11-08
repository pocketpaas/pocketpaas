package App::PocketPaas::Command::list;
use base qw(App::PocketPaas::Command);

# ABSTRACT: list applications

use strict;
use warnings;

use App::PocketPaas::Core;
use App::PocketPaas::App qw(load_app_names);

use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub options {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $pps = App::PocketPaas::Core->load_pps();

    my $app_names = load_app_names( $pps->config );

    print Dump($app_names);
}

1;
