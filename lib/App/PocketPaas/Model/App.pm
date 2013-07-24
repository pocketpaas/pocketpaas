package App::PocketPaas::Model::App;

use App::PocketPaas::Docker;
use App::PocketPaas::Util;

use JSON;
use File::Slurp qw(read_file write_file);

use Moo;

has name => ( is => 'ro' );

has containers => ( is => 'ro' );

has images => ( is => 'ro' );

sub load_all {
    my ($class) = @_;

    my @apps;

    my $apps_dir = App::PocketPaas->config->{brain} . '/apps';
    App::PocketPaas::Util->walk_dir(
        $apps_dir,
        sub {
            my $file = shift;
            my $app = $class->_load_app_from_file($file);

        }
    );

    return \@apps;
}

sub load {
    my ( $class, $name ) = @_;

    return $class->_load_app_from_file(App::PocketPaas->config->{brain} . '/apps' . '/' . $name);
}

sub _load_app_from_file {
    my ( $class, $file ) = @_;

    if (!-e $file) {
        return;
    }

    my $app_data = from_json(read_file($file));

    my $containers = [map {App::PocketPaas::Model::Container->new($_)} @{delete $app_data->{containers}}];
    my $images = [map {App::PocketPaas::Model::Image->new($_)} @{$app_data->{images}}];
    my $app = App::PocketPaas::Model::App->new({name => $app_data->{name}, containers => $containers, images => $images});

    return $app;
}

sub save {
    my ( $class, $app ) = @_;

    write_file(
        App::PocketPaas->config->{brain} . '/apps' . '/'
            . $app->name(),
        to_json( $app, { convert_blessed => 1, pretty => 1 } )
    );
}

sub TO_JSON {
    my $self = shift;
    return {
        name       => $self->name(),
        containers => $self->containers(),
        images     => $self->images(),
    };
}

1;
