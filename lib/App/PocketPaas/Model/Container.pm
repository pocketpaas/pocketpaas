package App::PocketPaas::Model::Container;

use Moo;

has docker_id => ( is => 'ro' );

has status => ( is => 'ro' );

sub TO_JSON {
    my $self = shift;
    return { docker_id => $self->docker_id(), };
}

1;
