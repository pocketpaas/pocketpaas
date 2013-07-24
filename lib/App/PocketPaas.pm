package App::PocketPaas;
use App::Cmd::Setup -app;

sub allow_any_unambiguous_abbrev { 1; }

sub config {
    return { brain => "$ENV{HOME}/.pocketpaas", };
}

1;
