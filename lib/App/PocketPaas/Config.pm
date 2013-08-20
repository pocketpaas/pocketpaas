package App::PocketPaas::Config;

use strict;
use warnings;

use App::PocketPaas::Notes;

use Log::Log4perl qw(:easy);
use Net::Domain qw(domainname);
use Readonly;

use Sub::Exporter -setup =>
    { exports => [qw(get_config set_config unset_config)] };

Readonly my $DEFAULT_BASE_DOMAIN          => domainname();
Readonly my $DEFAULT_BASE_DIR             => "$ENV{HOME}/.pocketpaas";
Readonly my $DEFAULT_APP_IMAGE_PREFIX     => 'pocketapp';
Readonly my $DEFAULT_BASE_IMAGE_PREFIX    => 'pocketbase';
Readonly my $DEFAULT_SERVICE_IMAGE_PREFIX => 'pocketsvc';

sub get_config {
    my ($class) = @_;

    my $note = App::PocketPaas::Notes->get_note('config');

    # TODO separate config keys into those that most people should care about
    # and those that only developers should care about

    return {
        domain   => $note->{domain}   || $DEFAULT_BASE_DOMAIN,
        base_dir => $note->{base_dir} || $DEFAULT_BASE_DIR,
        app_image_prefix => $note->{app_image_prefix}
            || $DEFAULT_APP_IMAGE_PREFIX,
        base_image_prefix => $note->{base_image_prefix}
            || $DEFAULT_BASE_IMAGE_PREFIX,
        svc_image_prefix => $note->{svc_image_prefix}
            || $DEFAULT_SERVICE_IMAGE_PREFIX,
    };
}

sub set_config {
    my ( $class, $key, $value ) = @_;

    # TODO validate key

    my $note = App::PocketPaas::Notes->get_note('config');
    $note->{$key} = $value;
    App::PocketPaas::Notes->add_note( 'config', $note );
}

sub unset_config {
    my ( $class, $key ) = @_;

    # TODO validate key

    my $note = App::PocketPaas::Notes->get_note('config');
    delete $note->{$key};
    App::PocketPaas::Notes->add_note( 'config', $note );
}

1;
