package App::PocketPaas::Service;

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Notes;
use App::PocketPaas::Model::Service;
use App::PocketPaas::Model::ServiceBase;

use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Readonly;
use IPC::Run3;
use File::Path qw(mkpath);

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mysql => 'https://github.com/pocketpaas/servicepack_mysql.git',
    redis => 'https://github.com/pocketpaas/servicepack_redis.git',
);

sub provision_service {
    my ( $class, $name, $type ) = @_;

    my $created = 1;
    my $service = $class->get($name);

    if ($service) {

        # TODO start service if not running
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
            App::PocketPaas::Docker->images() );

        # TODO don't duplicate the prefix here and in ServiceBase
        my $service_repo_base = "pocketbase/$type";
        if ( !$service_base ) {

            # build the base image
            run3 [
                qw(svp build -b), $service_clone_path,
                qw(-t),           $service_repo_base
            ];

            $service_base
                = App::PocketPaas::Model::ServiceBase->load( $type,
                App::PocketPaas::Docker->images() );
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
            = App::PocketPaas::Docker->run( $service_repo, { daemon => 1 } );

        # record information about the new service
        App::PocketPaas::Notes->add_note(
            "service_$name",
            {   docker_id    => $docker_id,
                env_template => $output,
                name         => $name,
                should_be    => 'running',
                type         => $type,
            }
        );

        $service = $class->get($name);
    }

    return wantarray ? ( $service, $created ) : $service;
}

sub stop_service {
    my ( $class, $name ) = @_;

    my $service = $class->get($name);

    if ($service) {
        my $app_notes = App::PocketPaas::Notes->query_notes(
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
                App::PocketPaas::Docker->stop( $service->docker_id );
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
    my ( $class, $name ) = @_;

    my $service = $class->get($name);

    if ($service) {
        if ( $service->status ne 'running' ) {
            App::PocketPaas::Docker->start( $service->docker_id );
            INFO("Service '$name' started.");
        }

        # TODO restart applications that depend on this service
    }
    else {
        WARN("Service '$name' not found.");
    }
}

sub get {
    my ( $class, $name ) = @_;

    # get type, docker_id from notes
    my $note = App::PocketPaas::Notes->get_note("service_$name");
    if ( scalar( keys(%$note) ) == 0 ) {
        return;
    }

    my $type           = $note->{type};
    my $docker_id      = $note->{docker_id};
    my $env_template   = $note->{env_template};
    my $container_info = App::PocketPaas::Docker->inspect($docker_id);

    # TODO handle empty container info

    return App::PocketPaas::Model::Service->load( $name, $type,
        $env_template, $container_info );
}

sub get_all {
    my ($class) = @_;

    # get type, docker_id from notes
    my $service_notes = App::PocketPaas::Notes->query_notes(
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
        my $container_info = App::PocketPaas::Docker->inspect($docker_id);

        push @$services,
            App::PocketPaas::Model::Service->load( $name, $type,
            $env_template, $container_info );
    }

    return $services;
}

1;
