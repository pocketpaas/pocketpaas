package App::PocketPaas::Service;

use strict;
use warnings;

use App::PocketPaas::Docker;

use Log::Log4perl qw(:easy);
use Readonly;
use IPC::Run3;

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mysql => 'https://github.com/pocketpaas/servicepack_mysql.git',
    redis => 'https://github.com/pocketpaas/servicepack_redis.git',
);

sub provision {
    my ( $class, $name, $type ) = @_;

    my $service = App::PocketPaas::Model::Service->load( $name, $type,
        App::PocketPaas::Docker->containers( { all => 1 } ) );

    if ($service) {

        # TODO start service if not running
        # return cached info, templated
        return;
    }

    my $svc_info_dir       = "$ENV{HOME}/.pocketpaas/service_info";
    my $service_clone_path = "$svc_info_dir/$type";

    if ( !-e $svc_info_dir ) {
        DEBUG("making service info directory $svc_info_dir");
        mkpath($svc_info_dir);
    }

    if ( !-e $service_clone_path ) {
        my $git_url = $SERVICE_TYPE_TO_GIT_URL{$type};
        DEBUG("cloning $git_url for service type $type");
        run3 [ qw(git clone --depth 1), $git_url, $service_clone_path ];
    }

    # build the base image
    # TODO check if base exists already
    my $service_repo_base = "pocketsvc/$type:base";

    run3 [ qw(svp build -b), $service_clone_path, qw(-t),
        $service_repo_base ];

    # create setup image and capture env variables
    my $service_repo = "pocketsvc/$type:$name";
    my $output;
    run3 [
        qw(svp setup -b), $service_clone_path,
        qw(-i),           $service_repo_base,
        qw(-t),           $service_repo
        ],
        undef, \$output;

    DEBUG("ENV: $output");

    # start the service
    App::PocketPaas::Docker->run( $service_repo, { daemon => 1 } );

    $service = App::PocketPaas::Model::Service->load( $name, $type,
        App::PocketPaas::Docker->containers( { all => 1 } ) );

    my $info       = App::PocketPaas::Docker->inspect( $service->docker_id );
    my $ip_address = $info->{NetworkSettings}{IPAddress};

    # template env variables
    $output =~ s/%IP/$ip_address/g;

    # TODO cache env variables

    return $output;
}

1;
