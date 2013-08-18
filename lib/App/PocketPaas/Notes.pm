package App::PocketPaas::Notes;

use strict;
use warnings;

use DirHandle;
use File::Slurp qw(read_file write_file);
use JSON;
use Log::Log4perl qw(:easy);
use File::Path qw(mkpath);

my $json = JSON->new->pretty;

sub add_note {
    my ( $class, $key, $contents ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    _ensure_notes_dir_exists($notes_dir);

    write_file( "$notes_dir/$key.json", $json->encode($contents) );
}

sub get_note {
    my ( $class, $key ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    _ensure_notes_dir_exists($notes_dir);

    my $note_file = "$notes_dir/$key.json";
    if ( -e $note_file ) {
        my $note_contents = read_file($note_file);
        return $json->decode($note_contents);
    }
    return {};
}

sub delete_note {
    my ( $class, $key ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    _ensure_notes_dir_exists($notes_dir);

    my $note_file = "$notes_dir/$key.json";
    if ( -e $note_file ) {
        unlink($note_file);
    }
}

sub query_notes {
    my ( $class, $query_sub ) = @_;

    my $notes_dir = "$ENV{HOME}/.pocketpaas/notes";
    _ensure_notes_dir_exists($notes_dir);

    my $matched_notes   = [];
    my $notes_dirhandle = DirHandle->new($notes_dir);
    while ( defined( my $entry = $notes_dirhandle->read ) ) {
        next if $entry eq '.' || $entry eq '..';

        my $key;
        ( $key = $entry ) =~ s/.json$//;

        my $note_file     = "$notes_dir/$entry";
        my $note_contents = $json->decode( scalar( read_file($note_file) ) );
        if ( $query_sub->( $entry, $note_contents ) ) {
            push @$matched_notes, { key => $key, contents => $note_contents };
        }
    }
    return $matched_notes;
}

sub _ensure_notes_dir_exists {
    my $notes_dir = shift;

    if ( !-e $notes_dir ) {
        DEBUG("making notes directory $notes_dir");
        mkpath($notes_dir);
    }
}

1;
