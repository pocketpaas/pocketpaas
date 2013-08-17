package App::PocketPaas::Service;

use strict;
use warnings;

use App::PocketPaas::Docker;
use App::PocketPaas::Notes;

use Log::Log4perl qw(:easy);
use Readonly;
use IPC::Run3;
use File::Path qw(mkpath);

Readonly my %SERVICE_TYPE_TO_GIT_URL => (
    mysql => 'https://github.com/pocketpaas/servicepack_mysql.git',
    redis => 'https://github.com/pocketpaas/servicepack_redis.git',
);

sub provision {
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

        # build the base image
        # TODO check if base exists already
        my $service_repo_base = "pocketsvc/$type:base";

        run3 [
            qw(svp build -b), $service_clone_path,
            qw(-t),           $service_repo_base
        ];

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
                should_be    => 'running',
                type         => $type,
            }
        );

        $service = $class->get($name);
    }

    return wantarray ? ( $service, $created ) : $service;
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

1;
