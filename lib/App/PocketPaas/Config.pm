package App::PocketPaas::Config;

use strict;
use warnings;

use App::PocketPaas::Notes qw(add_note get_note);

use Log::Log4perl qw(:easy);
use Net::Domain qw(domainname);
use Readonly;

use Sub::Exporter -setup =>
    { exports => [qw(get_public_config get_config set_config unset_config)] };

# default domain is either something that can be used with dnsmasq (in vagrant)
# or the domainname of the server
Readonly my $DEFAULT_BASE_DOMAIN => $ENV{USER} eq 'vagrant'
    ? 'pocketpaas.dev'
    : domainname();
Readonly my $DEFAULT_BASE_DIR             => "$ENV{HOME}/.pocketpaas";
Readonly my $DEFAULT_APP_IMAGE_PREFIX     => 'pocketapp';
Readonly my $DEFAULT_BASE_IMAGE_PREFIX    => 'pocketbase';
Readonly my $DEFAULT_SERVICE_IMAGE_PREFIX => 'pocketsvc';
Readonly my $DEFAULT_SERVICE_GIT_PREFIX   => 'https://github.com/pocketpaas/';

Readonly my @HIDDEN_KEYS => qw(base_dir svc_git_prefix);

sub get_public_config {
    my $config = get_config();

    delete $config->{$_} foreach @HIDDEN_KEYS;

    return $config;
}

sub get_config {
    my ($key) = @_;

    my $note = get_note( { base_dir => $DEFAULT_BASE_DIR }, 'config' );

    # TODO separate config keys into those that most people should care about
    # and those that only developers should care about

    my $config = {
        domain            => $note->{domain}            || $DEFAULT_BASE_DOMAIN,
        base_dir          => $note->{base_dir}          || $DEFAULT_BASE_DIR,
        app_image_prefix  => $note->{app_image_prefix}  || $DEFAULT_APP_IMAGE_PREFIX,
        base_image_prefix => $note->{base_image_prefix} || $DEFAULT_BASE_IMAGE_PREFIX,
        svc_image_prefix  => $note->{svc_image_prefix}  || $DEFAULT_SERVICE_IMAGE_PREFIX,
        svc_git_prefix    => $note->{svc_git_prefix}    || $DEFAULT_SERVICE_GIT_PREFIX,
    };

    return $key ? $config->{$key} // '' : $config;
}

sub set_config {
    my ( $key, $value ) = @_;

    # TODO validate key

    my $note = get_note( { base_dir => $DEFAULT_BASE_DIR }, 'config' );
    $note->{$key} = $value;
    add_note( { base_dir => $DEFAULT_BASE_DIR }, 'config', $note );
}

sub unset_config {
    my ($key) = @_;

    # TODO validate key

    my $note = get_note( { base_dir => $DEFAULT_BASE_DIR }, 'config' );
    delete $note->{$key};
    add_note( { base_dir => $DEFAULT_BASE_DIR }, 'config', $note );
}

1;
