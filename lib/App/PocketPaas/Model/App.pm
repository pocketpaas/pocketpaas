package App::PocketPaas::Model::App;

use App::PocketPaas::Model::Image;
use App::PocketPaas::Model::Container;
use List::MoreUtils qw(any);

use Moo;

has name => ( is => 'ro' );

has containers => ( is => 'ro' );

has images => ( is => 'ro' );

has status => ( is => 'ro' );

sub load {
    my ( $class, $config, $name, $docker_containers, $docker_images ) = @_;

    my ( @images, @containers );

    foreach my $docker_container (@$docker_containers) {
        if ( $docker_container->{Image}
            =~ m{^$config->{app_image_prefix}/$name:run-([\d-]+)$} )
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

    my $status;
    if ( any { $_->status() eq 'running' } @containers ) {
        $status = 'running';
    }
    else {
        $status = 'stopped';
    }

    my $potential_tags = {};
    foreach my $docker_image (@$docker_images) {
        if ( defined( $docker_image->{Repository} )
            && $docker_image->{Repository} eq
            "$config->{app_image_prefix}/$name" )
        {
            my ( $type, $tag )
                = $docker_image->{Tag} =~ m{^(build|run|temp)-([\d-]+)$};
            $potential_tags->{$tag}->{$type} = 1;
        }
    }
    foreach my $potential_tag ( keys %$potential_tags ) {
        if ( $potential_tags->{$potential_tag}->{build} ) {
            push @images,
                App::PocketPaas::Model::Image->new(
                { tag => $potential_tag } );
        }
    }

    if ( !@containers && !@images ) {
        return;
    }

    return $class->new(
        {   name       => $name,
            containers => \@containers,
            status     => $status,
            images     => [ sort { $b->{tag} cmp $a->{tag} } @images ],
        }
    );
}

sub load_names {
    my ( $class, $config, $docker_containers, $docker_images ) = @_;

    my $apps = {};
    foreach my $docker_container (@$docker_containers) {
        if ( my ($app_name)
            = $docker_container->{Image}
            =~ m{^$config->{app_image_prefix}/([^:]+):run-[\d-]+$} )
        {
            $apps->{$app_name}++;
        }
    }
    foreach my $docker_image (@$docker_images) {
        next if !defined( $docker_image->{Repository} );

        if ( my ($app_name)
            = $docker_image->{Repository}
            =~ m{$config->{app_image_prefix}/([^:]+)} )
        {
            $apps->{$app_name}++;
        }
    }

    return [ keys %$apps ];
}

sub load_all {
    my ( $class, $config, $docker_containers, $docker_images ) = @_;

    my $app_names
        = $class->load_names( $config, $docker_containers, $docker_images );
    return {
        map {
            $_ => $class->load( $config, $_, $docker_containers,
                $docker_images )
        } @$app_names
    };
}

1;
