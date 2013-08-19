package App::PocketPaas::Command::push;
use App::PocketPaas -command;

# ABSTRACT: build the current application

use strict;
use warnings;

use App::PocketPaas;
use App::PocketPaas::App;
use App::PocketPaas::Util;

use Cwd;
use File::Slurp qw(write_file);
use File::Temp qw(tempdir);
use IPC::Run3;
use Log::Log4perl qw(:easy);
use File::Path qw(make_path);

sub opt_spec {
    return (
        [   "name|n=s",
            "application name, defaults to the directory name or read from pps.yml"
        ],
        [   "stage|s",
            "run new code in a new container without replacing production"
        ],
        [ "no-cache",    "build without using a cache" ],
        [ "reset-cache", "reset the build cache" ],
        [ "service=s@",  "bind services to the application" ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::PocketPaas->setup();

    my $app_config = App::PocketPaas::Util->load_app_config( getcwd, $opt );

    my $app_name = $app_config->{name}
        || die "Please provide an application name with --name\n";

    App::PocketPaas::App->push_app($app_config);
}

1;
