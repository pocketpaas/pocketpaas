package App::PocketPaas::Task::StartApp;

use strict;
use warnings;

use App::PocketPaas::Docker qw( docker_containers docker_images);
use App::PocketPaas::Task::ProvisionService;
use App::PocketPaas::App qw(start_app);
use App::PocketPaas::Notes qw(add_note get_note);
use App::PocketPaas::Service qw(get_service);

use Log::Log4perl qw(:easy);

use Moo;

has pps      => ( is => 'ro' );
has name     => ( is => 'ro' );
has services => ( is => 'ro' );
has tag      => ( is => 'ro' );
has app      => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $pps, $name, $services, $tag, $app ) = @_;

    return {
        pps      => $pps,
        name     => $name,
        services => $services,
        tag      => $tag,
        app      => $app
    };
}

sub desc {
    return 'Start Application';
}

sub perform {
    my ($self) = @_;

    my $pps      = $self->pps;
    my $app_name = $self->name;
    my $services = $self->services;

    # TODO check for application already running

    my $app = $self->app;
    if ( !$app ) {
        $app = App::PocketPaas::Model::App->load(
            $pps->config, $app_name,
            docker_containers( $pps->config, { all => 1 } ),
            docker_images( $pps->config, )
        );
    }

    # validate tag
    my $tag = $self->tag;

    if ($tag) {

        # validate that tag exists
        if ( !grep { $_->tag() eq $tag } @{ $app->images } ) {
            die "Unable to find image for tag $tag.\n";
        }
    }
    else {
        # look in the note
        my $note = get_note( $pps->config, "app_$app_name", );
        if ( $note->{tag} ) {
            $tag = $note->{tag};
        }
        else {
            # fall back on the latest tag
            die "No images for app.\n" unless @{ $app->images };
            my $image = @{ $app->images }[0];
            $tag = $image->tag;
        }
    }

    # load services from the note if not passed in
    if ( !defined($services) ) {
        if ( my $note = get_note( $pps->config, "app_$app_name", ) ) {
            $services = $note->{services};
        }
    }

    my $service_env = '';

    my $services_needed_provisioning = 0;
    if ($services) {
        foreach my $service ( @{$services} ) {
            my $name = $service->{name};
            my $type = $service->{type};

            # TODO add support for a git url as the type

            my $service = get_service( $pps->config, $name );
            if ( $service && $service->status() eq 'running' ) {
                $service_env .= $service->env();
            }
            else {
                $services_needed_provisioning = 1;
                $pps->queue_task(
                    App::PocketPaas::Task::ProvisionService->new(
                        $pps, $name, $type
                    )
                );
            }
        }
    }
    if ($services_needed_provisioning) {
        die "end_of_line\n";
    }

    start_app( $pps->config, $app_name, $tag, $app, $service_env );

    add_note(
        $pps->config,
        "app_$app_name",
        {   services  => $services,
            name      => $app_name,
            should_be => 'running',
            tag       => $tag,
        }
    );
}

1;
