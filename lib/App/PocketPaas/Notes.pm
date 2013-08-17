package App::PocketPaas::Notes;

use strict;
use warnings;

use File::Slurp qw(read_file write_file);
use JSON;
use Log::Log4perl qw(:easy);
use File::Path qw(mkpath);

my $json = JSON->new->pretty;

sub add_note {
    my ( $class, $key, $contents ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    if ( !-e $notes_dir ) {
        DEBUG("making notes directory $notes_dir");
        mkpath($notes_dir);
    }

    write_file( "$notes_dir/$key.json", $json->encode($contents) );
}

sub get_note {
    my ( $class, $key ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    if ( !-e $notes_dir ) {
        DEBUG("making notes directory $notes_dir");
        mkpath($notes_dir);
    }

    my $note_file = "$notes_dir/$key.json";
    if ( -e $note_file ) {
        my $note_contents = read_file($note_file);
        return $json->decode($note_contents);
    }
    return {};
}

1;
