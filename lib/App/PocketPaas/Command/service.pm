package App::PocketPaas::Command::service;
use App::PocketPaas -command;

# ABSTRACT: manage pocketpaas services

use strict;
use warnings;

use App::PocketPaas::Service;

use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ( [ "name|n=s", "service name" ], [ "type|t=s", "service type" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $command = shift @$args;

    if ( $command eq 'create' ) {

        my $name = $opt->{name}
            || die "Please provide a service name with --name\n";
        my $type = $opt->{type}
            || die "Please provide a service type with --type\n";

        if ( my $env = App::PocketPaas::Service->provision( $name, $type ) ) {
            INFO("Service created");

            print "\n$env\n";
        }
        else {
            WARN("Service already exists");
        }
    }
    elsif ( $command eq 'list' ) {

        # TODO
    }
    elsif ( $command eq 'info' ) {

        my $name = $opt->{name}
            || die "Please provide a service name with --name\n";

        # TODO get/print the env variables too
        my $service = App::PocketPaas::Service->get($name);
        print Dump($service);
    }
    elsif ( $command eq 'stop' ) {

        # TODO
    }
    elsif ( $command eq 'start' ) {

        # TODO
    }
    elsif ( $command eq 'destroy' ) {

        # TODO
    }
    elsif ( $command eq 'client' ) {

        # TODO
    }
    elsif ( $command eq 'shell' ) {

        # TODO
    }
}

1;
