package App::PocketPaas::Command::config;
use base qw(App::PocketPaas::Command);

# ABSTRACT: configure pocketpaas

use strict;
use warnings;

use App::PocketPaas::Config qw(get_public_config get_config set_config unset_config);

use YAML qw(Dump);

sub options {
    return ( [ "unset|u=s", "unset a config key" ], [ "set|s=s", "set a config key" ], );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $key;
    if ( $key = $opt->{'unset'} ) {
        unset_config($key);
    }
    elsif ( $key = $opt->{'set'} ) {
        set_config( $key, $args->[0] );
    }
    elsif ( scalar(@$args) == 2 ) {
        set_config( $args->[0], $args->[1] );
    }
    elsif ( scalar(@$args) == 1 ) {
        printf "%s\n", get_config( $args->[0] );
    }
    elsif ( scalar(@$args) == 0 ) {
        print Dump( get_public_config() );
    }

}

1;
