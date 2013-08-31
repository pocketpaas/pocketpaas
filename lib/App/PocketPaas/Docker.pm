package App::PocketPaas::Docker;

use Cwd;
use IPC::Run3;
use JSON;
use Log::Log4perl qw(:easy);
use LWP::Protocol::http::SocketUnixAlt;
use LWP::UserAgent;
use Readonly;

use Sub::Exporter -setup => {
    exports => [
        qw(docker_containers docker_images docker_inspect docker_rmi docker_rm docker_start docker_stop docker_attach docker_run docker_commit docker_wait docker_build)
    ]
};

Readonly my @DOCKER => qw(docker);

LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnixAlt' );

sub docker_build {
    my ( $config, $directory, $tag ) = @_;

    my $dir_save = getcwd;

    chdir $directory;

    my @build_app_cmd = ( @DOCKER, qw(build -t), $tag, qw(.) );

    run3 \@build_app_cmd;

    my $rc = $? >> 8;

    chdir $dir_save;

    if ($rc) {
        WARN("build failed in $directory");
    }

    return !$rc;
}

sub docker_wait {
    my ( $config, $container ) = @_;

    run3 [ @DOCKER, qw(wait), $container ], \undef, \undef, \undef;

    my $rc = $? >> 8;

    return !$rc;
}

sub docker_commit {
    my $config = shift;
    my @args   = @_;

    run3 [ @DOCKER, qw(commit), @args ];
}

sub docker_run {
    my ( $config, $image, $options ) = @_;

    my @command;
    if ( $options->{command} ) {
        push @command, $options->{command};
    }

    my @args;
    if ( $options->{volumes} ) {
        push @args, '-v', $_ for @{ $options->{volumes} };
    }

    if ( $options->{ports} ) {
        push @args, '-p', $_ for @{ $options->{ports} };
    }

    if ( $options->{daemon} ) {

        my $output;
        run3 [ @DOCKER, qw(run -d), @args, $image, @command ], undef,
            \$output,
            \$output;

        chomp $output;

        DEBUG("run output: $output");

        # filter out warnings
        my @lines = grep { $_ !~ /WARNING/ } split( /\n/, $output );

        if ( scalar(@lines) == 1 && length( $lines[0] ) == 12 ) {
            return $lines[0];
        }
        else {
            WARN("run failed for image $image");
        }

        return 0;
    }
    else {
        run3 [ @DOCKER, qw(run), $image, @command ];
    }
}

sub docker_attach {
    my ( $config, $container ) = @_;

    my @run_cmd = ( @DOCKER, qw(attach), $container );

    run3 \@run_cmd;
}

sub docker_stop {
    my ( $config, $container_id ) = @_;

    my @run_cmd = ( @DOCKER, qw(stop), $container_id );

    run3 \@run_cmd, \undef, \undef, \undef;

    if ($rc) {
        WARN("stop failed for container $container_id");
    }

    return !$rc;
}

sub docker_start {
    my ( $config, $container_id ) = @_;

    my @run_cmd = ( @DOCKER, qw(start), $container_id );

    run3 \@run_cmd, \undef, \undef, \undef;

    if ($rc) {
        WARN("stop failed for container $container_id");
    }

    return !$rc;
}

sub docker_rm {
    my ( $config, $container_id ) = @_;

    my @run_cmd = ( @DOCKER, qw(rm), $container_id );

    run3 \@run_cmd;

    if ($rc) {
        WARN("rm failed for container $container_id");
    }

    return !$rc;
}

sub docker_rmi {
    my ( $config, $image ) = @_;

    my @run_cmd = ( @DOCKER, qw(rmi), $image );

    run3 \@run_cmd;

    if ($rc) {
        WARN("rmi failed for container $image");
    }

    return !$rc;
}

sub docker_containers {
    my ( $config, $args ) = @_;

    return _get( $config, '/containers/json' . _args($args) );
}

sub docker_images {
    my $config = shift;
    return _get( $config, '/images/json' );
}

sub docker_inspect {
    my ( $config, $container_id ) = @_;
    return _get( $config, "/containers/$container_id/json" );
}

sub _get {
    my ( $config, $uri ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $response = $ua->get( 'http:var/run/docker.sock//v1.4' . $uri );

    if ( $response->is_success ) {
        return decode_json( $response->decoded_content );
    }
}

sub _args {
    my $args = shift || return '';

    if ( scalar keys %$args ) {
        return '?' . join( '&', map {"$_=$args->{$_}"} keys %$args );
    }
}

1;
