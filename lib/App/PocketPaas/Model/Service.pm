package App::PocketPaas::Model::Service;

use Moo;

has name => ( is => 'ro' );

has type => ( is => 'ro' );

has docker_id => ( is => 'ro' );

has status => ( is => 'ro' );

has image => ( is => 'ro' );

sub load {
    my ( $class, $name, $type, $docker_containers ) = @_;

# {
#   'Id' => '8a79577a855d42713158aaaeff29552b765e07748ade5e5172d8a2814e614448',
#   'Status' => 'Up 13 minutes',
#   'Image' => 'pocketsvc/mysql:mydb',
#   'Ports' => '49154->22',
#   'Command' => '/usr/bin/supervisord',
#   'SizeRw' => 0,
#   'Created' => 1374714125,
#   'SizeRootFs' => 0
# }
    my ( $status, $docker_id, $image );
    foreach my $docker_container (@$docker_containers) {
        if ( $docker_container->{Image} =~ m{^pocketsvc/$type:$name$} ) {

            # TODO detect if multiple containers for same service name/type
            my $docker_status = $docker_container->{Status};
            if ( $docker_status =~ /^Up/ ) {
                $status = 'running';
            }
            elsif ( $docker_status =~ /^Exit/ ) {
                $status = 'stopped';
            }
            elsif ( $docker_status =~ /^Ghost/ ) {
                $status = 'ghost';
            }
            else {
                $status = 'unknown';
            }
            $docker_id = substr( $docker_container->{Id}, 0, 12 );
            $image = $docker_container->{Image};
        }
    }

    if ( !defined($status) ) {
        return;
    }

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
