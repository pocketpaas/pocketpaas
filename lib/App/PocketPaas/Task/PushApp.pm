package App::PocketPaas::Task::PushApp;

use strict;
use warnings;

use App::PocketPaas::Docker qw(docker_containers docker_images);
use App::PocketPaas::App qw(build_app);
use App::PocketPaas::Util qw(next_tag);
use App::PocketPaas::Model::App;
use App::PocketPaas::Task::StartApp;

use Log::Log4perl qw(:easy);

use Moo;

has pps        => ( is => 'ro' );
has app_config => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, $pps, $app_config ) = @_;

    return { pps => $pps, app_config => $app_config };
}

sub desc {
    return 'Push Application';
}

sub perform {
    my ($self) = @_;

    my $pps        = $self->pps;
    my $app_config = $self->app_config;

    my $app_name = $app_config->{name};

    my $app = App::PocketPaas::Model::App->load(
        $pps->config, $app_name,
        docker_containers( $pps->config, { all => 1 } ),
        docker_images( $pps->config, )
    );

    INFO("Pushing $app_name");

    my $tag = next_tag( $pps->config, $app );

    build_app( $pps->config, $app_name, $app_config, $tag, $app );

    # load app again so that it has the new image
    $app = App::PocketPaas::Model::App->load(
        $pps->config, $app_name,
        docker_containers( $pps->config, { all => 1 } ),
        docker_images( $pps->config, )
    );

    $pps->queue_task(
        App::PocketPaas::Task::StartApp->new(
            $pps, $app_name, $app_config->{services},
            $tag, $app, { force => 1 }
        )
    );
}

1;
