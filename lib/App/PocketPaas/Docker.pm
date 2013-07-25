package App::PocketPaas::Docker;

use Cwd;
use IPC::Run3;
use LWP::UserAgent;
use JSON;

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

sub run {
    my ( $class, $image, $options ) = @_;

    my @flags = ();

    push @flags, '-d' if $options->{daemon};

    my @run_cmd = ( qw(docker run), @flags, $image );

    run3 \@run_cmd;

    if ($rc) {
        WARN("run failed for image $image");
    }

    return !$rc;
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
