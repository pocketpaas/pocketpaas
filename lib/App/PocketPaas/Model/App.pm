package App::PocketPaas::Model::App;

use Moo;

has name => ( is => 'ro' );

has containers => ( is => 'ro' );

has images => ( is => 'ro' );

sub load {
    my ( $class, $name, $docker_containers, $docker_images ) = @_;

    my ( @images, @containers );

# {
#   'Id' => '8a79577a855d42713158aaaeff29552b765e07748ade5e5172d8a2814e614448',
#   'Status' => 'Up 13 minutes',
#   'Image' => 'minipaas/testapp:run-2013-07-24-03-28-15',
#   'Ports' => '49154->5000',
#   'Command' => '/start web',
#   'SizeRw' => 0,
#   'Created' => 1374714125,
#   'SizeRootFs' => 0
# }
    foreach my $docker_container (@$docker_containers) {
        if ( $docker_container->{Image} =~ m{^minipaas/$name:run-([\d-]+)$} )
        {
            my $tag           = $1;
            my $docker_status = $docker_container->{Status};
            my $status;
            if ( $docker_status =~ /^Up/ ) {
                $status = 'running';
            }
            elsif ( $docker_status =~ /^Exit/ ) {
                $status = 'stopped';
            }
            elsif ( $docker_status =~ /^Ghost/ ) {
                $status = 'ghost';
            }
            else {
                $status = 'unknown';
            }
            push @containers,
                App::PocketPaas::Model::Container->new(
                {   docker_id => substr( $docker_container->{Id}, 0, 12 ),
                    status    => $status,
                    tag       => $tag
                }
                );
        }
    }

# {
#   'Size' => 12288,
#   'Id' => '45d1d2933f039f2c7f647bb618ecaf612dc32d2a1ddd10a4ffafdaf6dd6e03a4',
#   'VirtualSize' => 679359403,
#   'Created' => 1374628038,
#   'Tag' => 'build-2013-07-24-00-58-11',
#   'Repository' => 'minipaas/testapp'
# },

    my $potential_tags = {};
    foreach my $docker_image (@$docker_images) {

        if ( $docker_image->{Repository} eq "minipaas/$name" ) {
            my ( $type, $tag )
                = $docker_image->{Tag} =~ m{^(build|run|temp)-([\d-]+)$};
            $potential_tags->{$tag}->{$type} = 1;
        }
    }
    foreach my $potential_tag ( keys %$potential_tags ) {
        if (   $potential_tags->{$potential_tag}->{build}
            && $potential_tags->{$potential_tag}->{run} )
        {
            push @images,
                App::PocketPaas::Model::Image->new(
                { tag => $potential_tag } );
        }
    }
    return App::PocketPaas::Model::App->new(
        {   name       => $name,
            containers => \@containers,
            images     => [ sort { $b->{tag} cmp $a->{tag} } @images ],
        }
    );
}

1;