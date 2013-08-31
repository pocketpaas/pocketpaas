package App::PocketPaas::Hipache;

use strict;
use warnings;

use App::PocketPaas::Docker qw(docker_inspect);
use App::PocketPaas::Service qw(get_service);

use Log::Log4perl qw(:easy);
use Redis;

use Sub::Exporter -setup => { exports => [qw(add_hipache_app)] };

sub add_hipache_app {
    my ( $config, $app_config, $docker_id ) = @_;

    INFO("Putting new application into hipache proxy");

    my $domain = $config->{domain};

    my $container_info = docker_inspect( $config, $docker_id );
    my $app_ip_address = $container_info->{NetworkSettings}{IPAddress};
    my $app_port       = 5000;
    DEBUG("Mapping $app_config->{name}.$domain to $app_ip_address:$app_port");

    my $hipache_service = get_service( $config, 'pps_hipache' );
    if ( !$hipache_service ) {
        WARN("PocketPaas Hipache service not found!!");
        return;
    }

    # get the hipache redis port from the hipache service environment
    my $env = $hipache_service->env;
    my ($redis_port) = $env =~ /POCKETPAAS_PPS_HIPACHE_REDIS_PORT=(\d+)/msi;
    my ($redis_host)
        = $env =~ /POCKETPAAS_PPS_HIPACHE_REDIS_HOST=([.\d]+)/msi;

    my $redis = Redis->new( server => "$redis_host:$redis_port" );

    my $hipache_key
        = sprintf( 'frontend:%s.%s', $app_config->{name}, $domain );

    DEBUG("del $hipache_key");
    $redis->del($hipache_key);
    DEBUG("rpush $hipache_key '$app_config->{name}'");
    $redis->rpush( $hipache_key, $app_config->{name} );
    DEBUG(
        sprintf(
            "rpush $hipache_key 'http://%s:%d'",
            $app_ip_address, $app_port
        )
    );
    $redis->rpush( $hipache_key,
        sprintf( 'http://%s:%d', $app_ip_address, $app_port ) );
}

1;
