package App::PocketPaas;
use App::Cmd::Setup -app;

use App::PocketPaas::Service;

use Log::Log4perl qw(:easy);

sub allow_any_unambiguous_abbrev { 1; }

sub config {
    return { brain => "$ENV{HOME}/.pocketpaas", };
}

sub setup {
    my ($class) = @_;

    # make sure hipache is running
    App::PocketPaas::Service->provision_service( 'pps_hipache', 'hipache',
        { ports => ['80:80'] } );
}

1;
