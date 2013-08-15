package App::PocketPaas::Util;

use DateTime;
use DirHandle;
use Log::Log4perl qw(:easy);
use Readonly;
use YAML qw(LoadFile);
use IPC::Run3;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);

use App::PocketPaas::Docker;
use App::PocketPaas::Model::Service;

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mysql => 'https://github.com/pocketpaas/servicepack_mysql.git',
    redis => 'https://github.com/pocketpaas/servicepack_redis.git',
);

Readonly my $POCKET_PAAS_CONFIG => 'pps.yml';

sub next_tag {
    my $app = shift;

    my $tag;
    my $now = DateTime->now();

    my $tag_to_image;
    if ($app) {
        $tag_to_image = { map { $_->tag() => 1 } @{ $app->images() } };
    }
    else {
        $tag_to_image = {};
    }

    my $i = 1;
    while ( $i < 1000 ) {
        $tag = $now->strftime( '%F-' . sprintf( '%03d', $i ) );
        last if !$tag_to_image->{$tag};
        $i++;
    }

    return $tag;
}

sub walk_dir {
    my ( $class, $dir, $handler ) = @_;
    if ( -d $dir ) {
        $d = DirHandle->new($dir);
        if ( defined $d ) {
            while ( defined( $_ = $d->read ) ) {
                next if $_ eq '..' || $_ eq '.';
                $handler->( $dir . '/' . $_ );
            }
        }
    }
}

sub load_app_config {
    my ( $class, $path, $options ) = @_;

    my $config = {};

    my $loaded_config = {};
    if ( -d $path ) {
        my $full_path = "$path/$POCKET_PAAS_CONFIG";
        if ( -e $full_path ) {
            $loaded_config = LoadFile($full_path);
        }

    }
    elsif ( -e $path ) {

        # TODO load from a tarball?
    }

    # TODO find config yaml if bare git repo
    # TODO find config yaml if up one dir
    # TODO fill in app name from parent dir if missing

    # TODO validate config

    $config->{name} = $options->{name} || $loaded_config->{name};

    # TODO consider joining two lists of services if both command line and
    # config file services were specified
    if ( $options->{service} ) {
        foreach my $service_spec ( @{ $options->{service} } ) {
            my ( $name, $type ) = split( /:/, $service_spec );
            push @{ $config->{services} }, { name => $name, type => $type };
        }
    }
    else {
        if ( $loaded_config->{services} ) {
            foreach my $service ( @{ $loaded_config->{services} } ) {
                my ($name) = keys %$service;
                my $type = $service->{$name};

                push @{ $config->{services} },
                    { name => $name, type => $type };
            }
        }
    }

    return $config;
}

sub provision_service {
    my ( $class, $name, $type ) = @_;

    my $service = App::PocketPaas::Model::Service->load( $name, $type,
        App::PocketPaas::Docker->containers( { all => 1 } ) );

    if ($service) {

        # TODO start service if not running
        # return cached info, templated
        return;
    }

    my $svc_info_dir       = "$ENV{HOME}/.pocketpaas/service_info";
    my $service_clone_path = "$svc_info_dir/service";

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
