package App::PocketPaas::Service;

use strict;
use warnings;

use App::PocketPaas::Docker
    qw(docker_images docker_inspect docker_run docker_start docker_stop);
use App::PocketPaas::Model::Service;
use App::PocketPaas::Model::ServiceBase;
use App::PocketPaas::Notes qw(add_note get_note query_notes);

use File::Path qw(mkpath);
use IPC::Run3;
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Readonly;

use Sub::Exporter -setup => {
    exports => [
        qw(provision_service stop_service start_service get_service get_all_services)
    ]
};

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mysql   => 'https://github.com/pocketpaas/servicepack_mysql.git',
    redis   => 'https://github.com/pocketpaas/servicepack_redis.git',
    hipache => 'https://github.com/pocketpaas/servicepack_hipache.git',
);

sub provision_service {
    my ( $config, $name, $type, $options ) = @_;

    my $created = 1;
    my $service = get_service( $config, $name );

    if ($service) {

        # start service if not running
        start_service( $config, $name );

        $created = 0;
    }
    else {

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

        # TODO for other kinds of services (non-servicepack), don't use this

        # check if base exists already
        my $service_base = App::PocketPaas::Model::ServiceBase->load( $type,
            docker_images($config) );

        # TODO don't duplicate the prefix here and in ServiceBase
        my $service_repo_base = "pocketbase/$type";
        if ( !$service_base ) {

            # build the base image
            run3 [
                qw(svp build -b), $service_clone_path,
                qw(-t),           $service_repo_base
            ];

            $service_base = App::PocketPaas::Model::ServiceBase->load( $type,
                docker_images($config) );
        }

        # create setup image and capture env variables
        my $service_repo = "pocketsvc/$name";
        my $output;
        run3 [
            qw(svp setup -b), $service_clone_path,
            qw(-i),           $service_repo_base,
            qw(-t),           $service_repo
            ],
            undef, \$output;

        DEBUG("ENV: $output");

        # start the service
        my $docker_id
            = docker_run( $config, $service_repo,
            { daemon => 1, ports => $options->{ports} } );

        # TODO check for !$docker_id and skip the note

        # record information about the new service
        add_note(
            $config,
            "service_$name",
            {   docker_id    => $docker_id,
                env_template => $output,
                name         => $name,
                should_be    => 'running',
                type         => $type,
            }
        );
    }

    # load service again to have latest env
    $service = get_service( $config, $name );

    return wantarray ? ( $service, $created ) : $service;
}

sub stop_service {
    my ( $config, $name ) = @_;

    my $service = get_service( $config, $name );

    if ($service) {
        my $app_notes = query_notes(
            $config,
            sub {
                my ( $key, $contents ) = @_;

                return 0 unless $key =~ /^app_/;
                return any { $_ eq $name } @{ $contents->{services} };
            }
        );

        # TODO only count apps that are running (or should be running)
        my $app_names = [ map { $_->{contents}{name} } @$app_notes ];

        if ( scalar @$app_names == 0 ) {
            if ( $service->status ne 'stopped' ) {
                docker_stop( $config, $service->docker_id );
                INFO("Service '$name' stopped.");
            }
        }
        else {
            WARN(
                      "Not stopping service '$name', applications ("
                    . join( ',', @$app_names )
                    . ") are using it.",
            );
        }
    }
    else {
        WARN("Service '$name' not found.");
    }
}

sub start_service {
    my ( $config, $name ) = @_;

    my $service = get_service( $config, $name );

    if ($service) {
        if ( $service->status ne 'running' ) {
            docker_start( $config, $service->docker_id );
            INFO("Service '$name' started.");
        }

        # TODO restart applications that depend on this service
    }
    else {
        WARN("Service '$name' not found.");
    }
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
    my $env_template   = $note->{env_template};
    my $container_info = docker_inspect( $config, $docker_id );

    # TODO handle empty container info

    return App::PocketPaas::Model::Service->load( $name, $type,
        $env_template, $container_info );
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
        my $env_template   = $contents->{env_template};
        my $container_info = docker_inspect( $config, $docker_id );

        push @$services,
            App::PocketPaas::Model::Service->load( $name, $type,
            $env_template, $container_info );
    }

    return $services;
}

1;
