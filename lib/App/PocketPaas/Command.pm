package App::PocketPaas::Command;

use App::Cmd::Setup -command;

use App::PocketPaas::Config qw(get_config);

use File::Path qw(mkpath);
use Log::Log4perl qw(:easy);

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        $class->options($app),
        [],    # insert a blank line
        [ 'help|h'    => 'this usage screen' ],
        [ 'verbose|v' => 'verbose output, shows debug messages' ],
        [ 'quiet|q'   => 'quiet output, only shows warnings' ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->{help} ) {
        my ($command) = $self->command_names;
        $self->app->execute_command( $self->app->prepare_command( "help", $command ) );
        exit;
    }

    my $console_log_level = 'INFO';
    if ( $opt->{verbose} ) {
        $console_log_level = 'DEBUG';
    }
    if ( $opt->{quiet} ) {
        $console_log_level = 'WARN';
    }

    my $config = get_config();
    if ( !-e $config->{base_dir} ) {
        mkpath( $config->{base_dir} );
    }

    Log::Log4perl->init( \ <<EOT);
  log4perl.category = DEBUG, Screen, File

  log4perl.filter.AtLeastDEBUG = Log::Log4perl::Filter::LevelRange
  log4perl.filter.AtLeastDEBUG.LevelMin = DEBUG
  log4perl.filter.AtLeastDEBUG.AcceptOnMatch = true

  log4perl.filter.AtLeastINFO = Log::Log4perl::Filter::LevelRange
  log4perl.filter.AtLeastINFO.LevelMin = INFO
  log4perl.filter.AtLeastINFO.AcceptOnMatch = true

  log4perl.filter.AtLeastWARN = Log::Log4perl::Filter::LevelRange
  log4perl.filter.AtLeastWARN.LevelMin = WARN
  log4perl.filter.AtLeastWARN.AcceptOnMatch = true

  log4perl.appender.Screen                          = Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout                   = PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = %p %m%n
  log4perl.appender.Screen.Filter                   = AtLeast$console_log_level

  log4perl.appender.File                          = Log::Log4perl::Appender::File
  log4perl.appender.File.filename                 = $ENV{HOME}/.pocketpaas/output.log
  log4perl.appender.File.layout                   = PatternLayout
  log4perl.appender.File.layout.ConversionPattern = %d %p (%c:%L)> %m%n
  log4perl.appender.File.Filter                   = AtLeastDEBUG
EOT

    if ( $self->can("validate") ) {
        return $self->validate( $opt, $args );
    }
}

1;
