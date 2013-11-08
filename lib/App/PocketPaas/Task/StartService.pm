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

            # if service was started, force restart any
            # apps that are bound to it
            my $app_names = find_apps_using_service( $pps->config, $name );
            foreach my $app_name (@$app_names) {

                # Instance where the startapp task is a duplicate:
                # * if more than one service is being started for a particular app
                # * if this service was started because the application is being started
                $pps->queue_task_unless_duplicate(
                    App::PocketPaas::Task::StartApp->new(
                        $pps, $app_name, undef, undef, undef, { force => 1 }
                    )
                );
            }
        }
    }
    else {
        WARN("Service '$name' not found.");
    }
}

1;
