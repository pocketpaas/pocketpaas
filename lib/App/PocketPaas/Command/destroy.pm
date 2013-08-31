package App::PocketPaas::Command::destroy;
use App::PocketPaas -command;

# ABSTRACT: delete the current application

use strict;
use warnings;

use App::PocketPaas::App qw(destroy_app);
use App::PocketPaas::Config qw(get_config);
use App::PocketPaas::Core qw(setup_pocketpaas);
use App::PocketPaas::Docker qw(docker_containers docker_images);
use App::PocketPaas::Util qw(load_app_config);
use App::PocketPaas::Model::App;

use Cwd;
use Log::Log4perl qw(:easy);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $config = get_config();
    setup_pocketpaas($config);

    my $app_config = load_app_config( $config, getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    my $app
        = App::PocketPaas::Model::App->load( $config, $app_name,
        docker_containers( $config, { all => 1 } ),
        docker_images($config) );

    if ( !$app ) {
        ERROR("No app by the name of $app_name");
        return;
    }

    # TODO add confirmation

    INFO("Destroying $app_name");

    destroy_app( $config, $app_config, $app );
}

1;
