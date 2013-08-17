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

        my $name = _get_name_opt($opt);
        my $type = _get_type_opt($opt);

        my ( $service, $created )
            = App::PocketPaas::Service->provision( $name, $type );

        if ($created) {
            INFO("Service created.");
        }
        else {
            INFO("Service already exists.");
        }
    }
    elsif ( $command eq 'list' ) {

        # TODO
    }
    elsif ( $command eq 'env' ) {

        my $name = _get_name_opt($opt);

        my $service = App::PocketPaas::Service->get($name)
            || LOGEXIT("Service '$name' not found.");

        print $service->env;
    }
    elsif ( $command eq 'info' ) {

        my $name = _get_name_opt($opt);

        my $service = App::PocketPaas::Service->get($name);

        print Dump(
            {   name      => $service->name,
                type      => $service->type,
                docker_id => $service->docker_id,
                status    => $service->status,
            }
        );
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

sub _get_name_opt {
    return shift->{name}
        || LOGEXIT("Please provide a service name with --name");
}

sub _get_type_opt {
    return shift->{type}
        || LOGEXIT("Please provide a service type with --type");
}

1;
