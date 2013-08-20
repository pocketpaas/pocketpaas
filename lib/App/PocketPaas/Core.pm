package App::PocketPaas::Core;

use App::PocketPaas::Service qw(provision_service);

use Log::Log4perl qw(:easy);

use Sub::Exporter -setup => { exports => [qw(setup_pocketpaas)] };

sub allow_any_unambiguous_abbrev { 1; }

sub setup_pocketpaas {
    my ($config) = @_;

    # make sure hipache is running
    provision_service( $config, 'pps_hipache', 'hipache',
        { ports => ['80:80'] } );
}

1;
