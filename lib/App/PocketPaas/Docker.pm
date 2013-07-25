package App::PocketPaas::Docker;

use Cwd;
use IPC::Run3;
use LWP::UserAgent;
use JSON;
use Log::Log4perl qw(:easy);

sub build {
    my ( $class, $directory, $tag ) = @_;

    my $dir_save = getcwd;

    chdir $directory;

    my @build_app_cmd = ( qw(docker build -t), $tag, qw(.) );

    run3 \@build_app_cmd;

    my $rc = $? >> 8;

    chdir $dir_save;

    if ($rc) {
        WARN("build failed in $directory");
    }

    return !$rc;
}

sub wait {
    my ( $class, $container ) = @_;

    run3 [ qw(docker wait), $container ], \undef, \undef, \undef;

    my $rc = $? >> 8;

    return !$rc;
}

sub commit {
    my $class = shift;
    my @args  = @_;

    run3 [ qw(docker commit), @args ];
}

sub run {
    my ( $class, $image, $options ) = @_;

    my @command;
    if ( $options->{command} ) {
        push @command, $options->{command};
    }

    my @args;
    if ( $options->{volumes} ) {
        push @args, '-v', $_ for @{ $options->{volumes} };
    }

    if ( $options->{daemon} ) {

        my $output;
        run3 [ qw(docker run -d), @args, $image, @command ], undef, \$output,
            \$output;

        chomp $output;

        DEBUG("run output: $output");

        if ( length($output) == 12 ) {
            return $output;
        }
        else {
            WARN("run failed for image $image");
        }

        return 0;
    }
    else {
        run3 [ qw(docker run), $image, @command ];
    }
}

sub attach {
    my ( $class, $container ) = @_;

    my @run_cmd = ( qw(docker attach), $container );

    run3 \@run_cmd;
}

sub stop {
    my ( $class, $container_id ) = @_;

    my @run_cmd = ( qw(docker stop), $container_id );

    run3 \@run_cmd;

    if ($rc) {
        WARN("stop failed for container $container_id");
    }

    return !$rc;
}

sub rm {
    my ( $class, $container_id ) = @_;

    my @run_cmd = ( qw(docker rm), $container_id );

    run3 \@run_cmd;

    if ($rc) {
        WARN("rm failed for container $container_id");
    }

    return !$rc;
}

sub containers {
    my ( $class, $args ) = @_;

    return $class->get( '/containers/json' . _args($args) );
}

sub images {
    my $class = shift;
    return $class->get('/images/json');
}

sub get {
    my ( $class, $uri ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $response = $ua->get( 'http://localhost:4243/v1.3' . $uri );

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
