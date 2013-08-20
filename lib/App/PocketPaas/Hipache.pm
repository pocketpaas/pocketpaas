package App::PocketPaas::Hipache;

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Service;

use Log::Log4perl qw(:easy);
use Redis;

sub add_app {
    my ( $class, $app_config, $docker_id ) = @_;

    INFO("Putting new application into hipache proxy");

    # TODO make this configurable
    my $domain = 'pocketpaas.com';

    my $container_info = App::PocketPaas::Docker->inspect($docker_id);
    my $app_ip_address = $container_info->{NetworkSettings}{IPAddress};
    my $app_port       = 5000;
    DEBUG("Mapping $app_config->{name}.$domain to $app_ip_address:$app_port");

    my $hipache_service = App::PocketPaas::Service->get('pps_hipache');
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
