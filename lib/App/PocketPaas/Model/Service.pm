package App::PocketPaas::Model::Service;

use strict;
use warnings;

use Moo;

has name      => ( is => 'ro' );
has type      => ( is => 'ro' );
has docker_id => ( is => 'ro' );
has status    => ( is => 'ro' );
has image     => ( is => 'ro' );
has env       => ( is => 'ro' );

sub load {
    my ( $class, $name, $type, $env, $docker_info ) = @_;

    if ( !$docker_info ) {
        return;
    }

    if ( ref($docker_info) eq 'ARRAY' ) {
        $docker_info = @{$docker_info}[0];
    }

    my ( $status, $docker_id, $image );

    $docker_id = substr( $docker_info->{ID}, 0, 12 );

    if ( $docker_info->{'State'}{'Running'} ) {
        $status = 'running';
    }
    elsif ( $docker_info->{'State'}{'Ghost'} ) {
        $status = 'ghost';
    }
    else {
        $status = 'stopped';
    }

    $image = $docker_info->{'Config'}{'Image'};

    # TODO: parse out port mappings so that Hipache.pm can find the public port

    return $class->new(
        {   name      => $name,
            type      => $type,
            image     => $image,
            docker_id => $docker_id,
            status    => $status,
            env       => $env,
        }
    );
}

1;
