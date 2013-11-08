package App::PocketPaas::Core;

use App::PocketPaas::Config qw(get_config);
use App::PocketPaas::Hipache qw(wait_for_hipache);
use App::PocketPaas::Task::ProvisionService;

use Moo;

has config => ( is => 'ro' );
has queue  => ( is => 'ro' );

use Log::Log4perl qw(:easy);

sub load_pps {
    my ($class) = @_;

    my $config = get_config();
    my $self = $class->new( { config => $config, queue => [] } );
    $self->setup_pocketpaas();

    return $self;
}

sub setup_pocketpaas {
    my ($self) = @_;

    # make sure hipache is running
    $self->queue_task(
        App::PocketPaas::Task::ProvisionService->new(
            $self, 'pps_hipache', 'hipache', { ports => [ '80:80', '127.0.0.1::6379' ] }
        )
    );
    $self->finish_queue();

    wait_for_hipache( $self->config );
}

sub queue_task {
    my ( $self, $task ) = @_;

    push @{ $self->queue }, $task;
}

sub finish_queue {
    my ($self) = @_;

    while ( @{ $self->queue } ) {

        #print STDERR Dumper( $self->queue );
        #use Data::Dumper;
        my $task = shift @{ $self->queue };
        eval {
            DEBUG( sprintf( "Performing task '%s'", $task->desc() ) );
            $task->perform();
        };
        if ($@) {
            if ( $@ =~ /end_of_line/ ) {
                push @{ $self->queue }, $task;
            }
            else {
                die $@;
            }
        }
    }
}

1;
