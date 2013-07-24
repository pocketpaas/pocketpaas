package App::PocketPaas::Model::Image;

use Moo;

has tag => ( is => 'ro' );

sub build_tag {
    return 'build-' . shift->tag();
}

sub run_tag {
    return 'run-' . shift->tag();
}

sub TO_JSON {
    my $self = shift;
    return { tag => $self->tag(), };
}

1;
