package App::PocketPaas::Task::StartService;

use strict;
use warnings;

use App::PocketPaas::Service qw(start_service get_service );
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
    return 'Start Service';
}

sub perform {
    my ($self) = @_;

    my $pps  = $self->pps;
    my $name = $self->name;

    my $service = get_service( $self->pps->config, $name );

    if ($service) {
        if ( start_service( $pps->config, $name ) ) {

            # if service was started, restart any apps that are bound to it
            # TODO change this to restart when start doesn't restart
            my $app_names = find_apps_using_service( $pps->config, $name );
            foreach my $app_name (@$app_names) {
                $pps->queue_task(
                    App::PocketPaas::Task::StartApp->new( $pps, $app_name ) );
            }
        }
    }
    else {
        WARN("Service '$name' not found.");
    }
}

1;
