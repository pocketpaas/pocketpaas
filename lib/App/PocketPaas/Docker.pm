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

sub containers {
    my $class = shift;
    return $class->get('/containers/json');
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

1;
