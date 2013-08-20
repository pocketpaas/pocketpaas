package App::PocketPaas::Command::service;
use App::PocketPaas -command;

# ABSTRACT: manage pocketpaas services

use strict;
use warnings;

use App::PocketPaas;
use App::PocketPaas::Service;

use IPC::Run3;
use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ( [ "name|n=s", "service name" ], [ "type|t=s", "service type" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::PocketPaas->setup();

    my $command = shift @$args;

    if ( $command eq 'create' ) {

        my $name = _get_name_opt($opt);
        my $type = _get_type_opt($opt);

        my ( $service, $created )
            = App::PocketPaas::Service->provision_service( $name, $type );

        if ($created) {
            INFO("Service created.");
        }
        else {
            INFO("Service already exists.");
        }
    }
    elsif ( $command eq 'list' ) {

        my $services = App::PocketPaas::Service->get_all();

        print Dump( [ map { $_->{name} } @$services ] );
    }
    elsif ( $command eq 'env' ) {

        my $service = _get_service( _get_name_opt($opt) );

        print $service->env;
    }
    elsif ( $command eq 'info' ) {

        my $service = _get_service( _get_name_opt($opt) );

        print Dump(
            {   name      => $service->name,
                type      => $service->type,
                docker_id => $service->docker_id,
                status    => $service->status,
            }
        );
    }
    elsif ( $command eq 'stop' ) {
        my $name    = _get_name_opt($opt);
        my $service = _get_service($name);

        # TODO prevent stopping core pps services

        App::PocketPaas::Service->stop_service($name);
    }
    elsif ( $command eq 'start' ) {
        my $name    = _get_name_opt($opt);
        my $service = _get_service($name);

        App::PocketPaas::Service->start_service($name);
    }
    elsif ( $command eq 'destroy' ) {

        # TODO
    }
    elsif ( $command eq 'client' ) {

        my $service = _get_service( _get_name_opt($opt) );

        # call out to servicepack
        run3 [ qw(svp client -c), $service->docker_id, ];
    }
    elsif ( $command eq 'shell' ) {

        my $service = _get_service( _get_name_opt($opt) );

        # call out to servicepack
        run3 [ qw(svp shell -c), $service->docker_id, ];
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

sub _get_service {
    my $name = shift;
    return App::PocketPaas::Service->get($name)
        || LOGEXIT("Service '$name' not found.");
}

1;
