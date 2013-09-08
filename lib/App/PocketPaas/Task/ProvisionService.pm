package App::PocketPaas::Task::ProvisionService;

use strict;
use warnings;

use App::PocketPaas::Service qw(get_service);
use App::PocketPaas::Task::CreateService;
use App::PocketPaas::Task::StartService;

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
    return 'Provision Service';
}

sub perform {
    my ($self) = @_;

    my $name = $self->name;
    my $pps  = $self->pps;

    my $service = get_service( $pps->config, $name );

    if ($service) {
        $pps->queue_task( App::PocketPaas::Task::StartService->new( $pps, $name ) );
    }
    else {
        $pps->queue_task(
            App::PocketPaas::Task::CreateService->new( $pps, $name, $self->type, $self->options ) );
    }

}

1;
