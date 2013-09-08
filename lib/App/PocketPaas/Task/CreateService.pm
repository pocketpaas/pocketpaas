package App::PocketPaas::Task::CreateService;

use strict;
use warnings;

use App::PocketPaas::Service qw(create_service);

use Log::Log4perl qw(:easy);

use Moo;

has pps     => ( is => 'ro' );
has name    => ( is => 'ro' );
has type    => ( is => 'ro' );
has options => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $pps, $name, $type, $options ) = @_;

    return { pps => $pps, name => $name, type => $type, options => $options };
}

sub desc {
    return 'Create Service';
}

sub perform {
    my ($self) = @_;

    create_service( $self->pps->config, $self->name, $self->type, $self->options );
}

1;
