package App::PocketPaas::Model::Container;

use Moo;

has docker_id => ( is => 'ro' );

has status => ( is => 'ro' );

has tag => ( is => 'ro' );

1;
