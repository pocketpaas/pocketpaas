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
has ports     => ( is => 'ro' );
has link_name => ( is => 'ro' );

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

    my $ports = $docker_info->{'NetworkSettings'}{'Ports'};
    $ports = { map { $_ => $ports->{$_}[0]{'HostPort'} } keys %$ports };

    return $class->new(
        {   name      => $name,
            type      => $type,
            image     => $image,
            docker_id => $docker_id,
            status    => $status,
            env       => $env,
            ports     => $ports,
            link_name => $docker_info->{'Name'},
        }
    );
}

1;
