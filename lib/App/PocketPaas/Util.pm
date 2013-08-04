package App::PocketPaas::Util;

use DateTime;
use DirHandle;

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

1;
