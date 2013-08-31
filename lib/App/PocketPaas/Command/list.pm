package App::PocketPaas::Command::list;
use App::PocketPaas -command;

# ABSTRACT: list applications

use strict;
use warnings;

use App::PocketPaas::Core qw(setup_pocketpaas);
use App::PocketPaas::Config qw(get_config);
use App::PocketPaas::Docker qw(docker_containers docker_images);
use App::PocketPaas::Model::App;

use Log::Log4perl qw(:easy);
use YAML qw(Dump);

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $config = get_config();
    setup_pocketpaas($config);

    my $app_names
        = App::PocketPaas::Model::App->load_names( $config,
        docker_containers( $config, { all => 1 } ),
        docker_images($config) );

    print Dump($app_names);
}

1;
