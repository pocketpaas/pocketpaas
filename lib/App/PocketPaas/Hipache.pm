package App::PocketPaas::Hipache;

use strict;
use warnings;

use App::PocketPaas::Docker qw(docker_inspect);
use App::PocketPaas::Service qw(get_service);

use Log::Log4perl qw(:easy);
use Redis;

use Sub::Exporter -setup => { exports => [qw(wait_for_hipache add_hipache_app)] };

sub wait_for_hipache {
    my ($config) = @_;

    my $hipache_service = get_service( $config, 'pps_hipache' );
    if ( !$hipache_service ) {
        WARN("PocketPaas Hipache service not found!!");
        return;
    }

    # get the hipache redis port from the hipache service
    my $redis_port = $hipache_service->ports->{'6379/tcp'};

    my $redis = Redis->new( server => "localhost:$redis_port" );

    while ( !$redis->ping ) {
        DEBUG("waiting for hipache on local port $redis_port...");
        sleep 1;
        $redis = Redis->new( server => "localhost:$redis_port" );
    }
}

sub add_hipache_app {
    my ( $config, $app_name, $docker_id ) = @_;

    INFO("Putting new application into hipache proxy");

    my $domain = $config->{domain};

    my $container_info = docker_inspect( $config, $docker_id );
    my $app_ip_address = $container_info->{NetworkSettings}{IPAddress};
    my $app_port       = 5000;
    DEBUG("Mapping $app_name.$domain to $app_ip_address:$app_port");

    my $hipache_service = get_service( $config, 'pps_hipache' );
    if ( !$hipache_service ) {
        WARN("PocketPaas Hipache service not found!!");
        return;
    }

    # get the hipache redis port from the hipache service
    my $redis_port = $hipache_service->ports->{'6379/tcp'};

    my $redis = Redis->new( server => "localhost:$redis_port" );

    my $hipache_key = sprintf( 'frontend:%s.%s', $app_name, $domain );

    DEBUG("del $hipache_key");
    $redis->del($hipache_key);
    DEBUG("rpush $hipache_key '$app_name'");
    $redis->rpush( $hipache_key, $app_name );
    DEBUG( sprintf( "rpush $hipache_key 'http://%s:%d'", $app_ip_address, $app_port ) );
    $redis->rpush( $hipache_key, sprintf( 'http://%s:%d', $app_ip_address, $app_port ) );
}

1;
