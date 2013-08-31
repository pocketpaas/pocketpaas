package App::PocketPaas::Model::ServiceBase;

use strict;
use warnings;

use Moo;

has type => ( is => 'ro' );
has repo => ( is => 'ro' );
has tags => ( is => 'ro' );

sub load {
    my ( $class, $config, $type, $docker_images ) = @_;

    my $repo = "$config->{base_image_prefix}/$type";
    my $tags = [];

    foreach my $docker_image (@$docker_images) {

        if ( defined( $docker_image->{Repository} )
            && $docker_image->{Repository} eq
            "$config->{base_image_prefix}/$type" )
        {
            push @$tags, $docker_image->{Tag};
        }
    }

    if ( scalar @$tags == 0 ) {
        return;
    }

    return $class->new(
        {   type => $type,
            repo => $repo,
            tags => $tags,
        }
    );
}

1;
