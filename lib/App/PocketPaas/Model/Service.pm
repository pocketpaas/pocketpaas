package App::PocketPaas::Model::Service;

use strict;
use warnings;

use Moo;

has name         => ( is => 'ro' );
has type         => ( is => 'ro' );
has docker_id    => ( is => 'ro' );
has status       => ( is => 'ro' );
has image        => ( is => 'ro' );
has env          => ( is => 'ro' );
has env_template => ( is => 'ro' );

sub load {
    my ( $class, $name, $type, $env_template, $docker_info ) = @_;

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

    # template env variables
    # (only ip addr for now, maybe ports in the future)
    my $ip_address = $docker_info->{NetworkSettings}{IPAddress};

    my $env = $env_template;
    $env =~ s/%IP/$ip_address/g;

    my $uc_name = uc($name);
    $env =~ s/^/POCKETPAAS_${uc_name}_/gms;

    return App::PocketPaas::Model::Service->new(
        {   name         => $name,
            type         => $type,
            image        => $image,
            docker_id    => $docker_id,
            status       => $status,
            env_template => $env_template,
            env          => $env,
        }
    );
}

1;
