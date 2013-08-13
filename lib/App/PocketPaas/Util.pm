package App::PocketPaas::Util;

use DateTime;
use DirHandle;
use Log::Log4perl qw(:easy);
use Readonly;
use YAML qw(LoadFile);

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

    return $config;
}

1;
