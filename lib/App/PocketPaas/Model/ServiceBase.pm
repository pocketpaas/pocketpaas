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
        foreach my $tag ( @{ $docker_image->{RepoTags} } ) {
            if ( $tag =~ m{^$config->{base_image_prefix}/$type:(.+)$} ) {
                push @$tags, $1;
            }
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
