package App::PocketPaas::Task::StopService;

use strict;
use warnings;

use App::PocketPaas::Service qw(stop_service get_service );
use App::PocketPaas::App qw(find_apps_using_service);

use Log::Log4perl qw(:easy);

use Moo;

has pps  => ( is => 'ro' );
has name => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $pps, $name, $type ) = @_;

    return { pps => $pps, name => $name };
}

sub desc {
    return 'Stop Service';
}

sub perform {
    my ($self) = @_;

    my $pps  = $self->pps;
    my $name = $self->name;

    my $service = get_service( $self->pps->config, $name );

    if ($service) {
        my $app_names = find_apps_using_service( $pps->config, $name );

        if ( scalar @$app_names == 0 ) {
            stop_service( $pps->config, $name );
        }
        else {
            WARN(
                      "Not stopping service '$name', applications ("
                    . join( ',', @$app_names )
                    . ") are using it.",
            );
        }
    }
    else {
        WARN("Service '$name' not found.");
    }
}

1;
