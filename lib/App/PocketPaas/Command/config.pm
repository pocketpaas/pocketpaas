package App::PocketPaas::Command::config;
use App::PocketPaas -command;

# ABSTRACT: configure pocketpaas

use strict;
use warnings;

use App::PocketPaas::Config;

use YAML qw(Dump);

sub opt_spec {
    return (
        [ "unset|u=s", "unset a config key" ],
        [ "set|s=s",   "set a config key" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $key;
    if ( $key = $opt->{'unset'} ) {
        App::PocketPaas::Config->unset_config($key);
    }
    elsif ( $key = $opt->{'set'} ) {
        App::PocketPaas::Config->set_config( $key, $args->[0] );
    }
    elsif ( scalar(@$args) == 2 ) {
        App::PocketPaas::Config->set_config( $args->[0], $args->[1] );
    }
    elsif ( scalar(@$args) == 0 ) {
        print Dump( App::PocketPaas::Config->get_config() );
    }

}

1;
