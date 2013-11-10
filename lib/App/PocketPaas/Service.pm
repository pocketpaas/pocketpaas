package App::PocketPaas::Service;

use strict;
use warnings;

use App::PocketPaas::Docker qw(docker_images docker_inspect docker_run docker_start docker_stop);
use App::PocketPaas::Model::Service;
use App::PocketPaas::Model::ServiceBase;
use App::PocketPaas::Notes qw(add_note get_note query_notes);

use File::Path qw(mkpath);
use IPC::Run3;
use Log::Log4perl qw(:easy);
use Readonly;

use Sub::Exporter -setup =>
    { exports => [qw(create_service stop_service start_service get_service get_all_services)] };

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mongodb => 'servicepack_mongodb.git',
    mysql   => 'servicepack_mysql.git',
    redis   => 'servicepack_redis.git',
    hipache => 'servicepack_hipache.git',
);

sub create_service {
    my ( $config, $name, $type, $options ) = @_;

    my $svc_info_dir       = "$config->{base_dir}/service_info";
    my $service_clone_path = "$svc_info_dir/$type";

    if ( !-e $svc_info_dir ) {
        DEBUG("making service info directory $svc_info_dir");
        mkpath($svc_info_dir);
    }

    # TODO: update the repo (git pull) if it already exists
    if ( !-e $service_clone_path ) {
        my $git_repo = $SERVICE_TYPE_TO_GIT_URL{$type};
        my $git_url  = $config->{svc_git_prefix} . $git_repo;
        DEBUG("cloning $git_url for service type $type");
        run3 [ qw(git clone --depth 1), $git_url, $service_clone_path ];
    }

    # TODO for other kinds of services (non-servicepack), don't use this

    # check if base exists already
    my $service_base
        = App::PocketPaas::Model::ServiceBase->load( $config, $type, docker_images($config) );

    my $service_repo_base = "$config->{base_image_prefix}/$type";
    if ( !$service_base ) {

        # build the base image
        run3 [ qw(svp build -b), $service_clone_path, qw(-t), $service_repo_base ];

        $service_base
            = App::PocketPaas::Model::ServiceBase->load( $config, $type, docker_images($config) );
    }

    # create setup image and capture env variables
    my $service_repo = "$config->{svc_image_prefix}/$name";

    my $env;
    run3 [ qw(svp setup -b), $service_clone_path, qw(-i), $service_repo_base,
        qw(-t), $service_repo ],
        undef, \$env;

    DEBUG("ENV: $env");
    my $environment = [ split( /\n/, $env ) ];

    my $ports_raw;
    run3 [ qw(svp ports -b), $service_clone_path, ], undef, \$ports_raw;

    DEBUG("PORTS: $ports_raw");
    my $container_ports = [ split( /\n/, $ports_raw ) ];

    # ssh port for connecting to service
    my @base_ports = qw(127.0.0.1::22);

    if ( $options->{ports} ) {
        foreach my $port_spec ( @{ $options->{ports} } ) {
            my ( $ip, $public, $private ) = $port_spec =~ m/(?:(\d+\.[\d.]+):)?(?:(\d*):)?(\d+)/;

            $container_ports = [ grep { $_ != $private } @$container_ports ];
            push( @base_ports, $port_spec );
        }
    }

    # start the service
    my $docker_id = docker_run(
        $config,
        $service_repo,
        {   daemon      => 1,
            expose      => $container_ports,
            ports       => \@base_ports,
            environment => $environment,
            name        => "service_$name",
        }
    );

    # TODO check for !$docker_id and skip the note

    # record information about the new service
    add_note(
        $config,
        "service_$name",
        {   docker_id => $docker_id,
            env       => $environment,
            name      => $name,
            should_be => 'running',
            type      => $type,
        }
    );
}

sub stop_service {
    my ( $config, $name ) = @_;

    my $service = get_service( $config, $name );

    if ($service) {
        if ( $service->status ne 'stopped' ) {
            docker_stop( $config, $service->docker_id );
            INFO("Service '$name' stopped.");
            return 1;
        }
    }
    return 0;
}

sub start_service {
    my ( $config, $name ) = @_;

    my $service = get_service( $config, $name );

    if ($service) {
        if ( $service->status ne 'running' ) {
            docker_start( $config, $service->docker_id );
            INFO("Service '$name' started.");
            return 1;
        }
    }
    else {
        WARN("Service '$name' not found.");
    }
    return 0;
}

sub get_service {
    my ( $config, $name ) = @_;

    # get type, docker_id from notes
    my $note = get_note( $config, "service_$name" );
    if ( scalar( keys(%$note) ) == 0 ) {
        return;
    }

    my $type           = $note->{type};
    my $docker_id      = $note->{docker_id};
    my $env            = $note->{env};
    my $container_info = docker_inspect( $config, $docker_id );

    # TODO handle empty container info

    return App::PocketPaas::Model::Service->load( $name, $type, $env, $container_info );
}

sub get_all_services {
    my ($config) = @_;

    # get type, docker_id from notes
    my $service_notes = query_notes(
        $config,
        sub {
            my ( $key, $contents ) = @_;
            return $key =~ /^service_/;
        }
    );

    my $services = [];

    foreach my $note (@$service_notes) {
        my $key      = $note->{key};
        my $contents = $note->{contents};

        my $name           = $contents->{name};
        my $type           = $contents->{type};
        my $docker_id      = $contents->{docker_id};
        my $env            = $contents->{env};
        my $container_info = docker_inspect( $config, $docker_id );

        push @$services,
            App::PocketPaas::Model::Service->load( $name, $type, $env, $container_info );
    }

    return $services;
}

1;
