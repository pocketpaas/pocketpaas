package App::PocketPaas::Task::DestroyApp;

use strict;
use warnings;

use App::PocketPaas::App qw(destroy_app);

use Log::Log4perl qw(:easy);

use Moo;

has pps        => ( is => 'ro' );
has app_config => ( is => 'ro' );
has app        => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $pps, $app_config, $app ) = @_;

    return {
        pps        => $pps,
        app_config => $app_config,
        app        => $app
    };
}

sub desc {
    return 'Destroy Application';
}

sub perform {
    my ($self) = @_;

    destroy_app( $self->pps->config, $self->app_config, $self->app );
}

1;
