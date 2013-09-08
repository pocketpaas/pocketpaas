package App::PocketPaas::Command::service;
use App::PocketPaas -command;

# ABSTRACT: manage pocketpaas services

use strict;
use warnings;

use App::PocketPaas::Core;
use App::PocketPaas::Service qw(get_service get_all_services stop_service start_service);
use App::PocketPaas::Task::StopService;
use App::PocketPaas::Task::StartService;
use App::PocketPaas::Task::ProvisionService;

use IPC::Run3;
use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ( [ "name|n=s", "service name" ], [ "type|t=s", "service type" ], );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $pps = App::PocketPaas::Core->load_pps();

    my $command = shift @$args;

    if ( $command eq 'create' ) {

        my $name = _get_name_opt($opt);
        my $type = _get_type_opt($opt);

        $pps->queue_task( App::PocketPaas::Task::ProvisionService->new( $pps, $name, $type ) );
    }
    elsif ( $command eq 'list' ) {

        my $services = get_all_services( $pps->config );

        print Dump( [ map { $_->{name} } @$services ] );
    }
    elsif ( $command eq 'env' ) {

        my $service = _get_service( $pps->config, _get_name_opt($opt) );

        print $service->env;
    }
    elsif ( $command eq 'info' ) {

        my $service = _get_service( $pps->config, _get_name_opt($opt) );

        print Dump(
            {   name      => $service->name,
                type      => $service->type,
                docker_id => $service->docker_id,
                status    => $service->status,
            }
        );
    }
    elsif ( $command eq 'stop' ) {
        my $name = _get_name_opt($opt);
        my $service = _get_service( $pps->config, $name );

        # TODO prevent stopping core pps services

        $pps->queue_task( App::PocketPaas::Task::StopService->new( $pps, $name ) );
    }
    elsif ( $command eq 'start' ) {
        my $name = _get_name_opt($opt);
        my $service = _get_service( $pps->config, $name );

        $pps->queue_task( App::PocketPaas::Task::StartService->new( $pps, $name ) );
    }
    elsif ( $command eq 'destroy' ) {

        # TODO
    }
    elsif ( $command eq 'client' ) {

        my $service = _get_service( $pps->config, _get_name_opt($opt) );

        # call out to servicepack
        run3 [ qw(svp client -c), $service->docker_id, ];
    }
    elsif ( $command eq 'shell' ) {

        my $service = _get_service( $pps->config, _get_name_opt($opt) );

        # call out to servicepack
        run3 [ qw(svp shell -c), $service->docker_id, ];
    }

    $pps->finish_queue();
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
    my ( $config, $name ) = @_;
    return get_service( $config, $name )
        || LOGEXIT("Service '$name' not found.");
}

1;
