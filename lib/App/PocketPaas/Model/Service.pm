package App::PocketPaas::Model::Service;

use Moo;

has name => ( is => 'ro' );

has type => ( is => 'ro' );

has docker_id => ( is => 'ro' );

has status => ( is => 'ro' );

has image => ( is => 'ro' );

sub load {
    my ( $class, $name, $type, $docker_id, $docker_containers ) = @_;

    my ( $status, $real_docker_id, $image, $service_container );
    if ( defined($docker_id) ) {
        ($service_container)
            = grep { $_->{Id} =~ /^$docker_id/ } @$docker_containers;

        if ($service_container) {
            $real_docker_id = $docker_id;
        }
    }
    else {

        # look for the service in the list of running containers
        foreach my $docker_container (@$docker_containers) {

            # TODO detect if multiple containers for same service name
            if ( $docker_container->{Image} =~ m{^pocketsvc/$name:latest$} ) {

                $service_container = $docker_container;
                $real_docker_id = substr( $service_container->{Id}, 0, 12 );
            }
        }

    }

    if ( !defined($real_docker_id) ) {
        return;
    }

    $status = App::PocketPaas::Util->docker_status_to_internal(
        $service_container->{Status} );
    $image = $service_container->{Image};

    return App::PocketPaas::Model::Service->new(
        {   name      => $name,
            type      => $type,
            image     => $image,
            docker_id => $docker_id,
            status    => $status,
        }
    );
}

sub load_names {
    my ( $class, $docker_containers ) = @_;

    my $services = [];
    foreach my $docker_container (@$docker_containers) {
        if ( my ( $type, $name )
            = $docker_container->{Image} =~ m{^pocketsvc/([^:]+):([^:]+)$} )
        {
            next if $name eq 'base';
            push @$services, { type => $type, name => $name };
        }
    }

    return $services;
}

sub load_all {
    my ( $class, $docker_containers ) = @_;

    my $services = $class->load_names($docker_containers);
    return [
        map { $class->load( $_->{name}, $_->{type}, $docker_containers ) }
            @$services
    ];
}

1;
