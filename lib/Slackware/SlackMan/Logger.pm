package Slackware::SlackMan::Logger;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.1.0_11';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{}

}

use Time::Piece;

use constant LOGGER_LEVELS => qw(EMERG ALERT CRIT ERR WARN NOTICE INFO DEBUG);

# RFC 5424 levels (debug, info, notice, warning, error, critical, alert, emergency)
use constant EMERG     => 0;  # Emergency: system is unusable
use constant ALERT     => 1;  # Alert: action must be taken immediately
use constant CRIT      => 2;  # Critical: critical conditions
use constant ERR       => 3;  # Error: error conditions
use constant WARN      => 4;  # Warning: warning conditions
use constant NOTICE    => 5;  # Notice: normal but significant condition
use constant INFO      => 6;  # Informational: informational messages
use constant DEBUG     => 7;  # Debug: debug messages

# Log level alias
use constant EMERGENCY => 0;
use constant CRITICAL  => 2;
use constant ERROR     => 3;
use constant WARNING   => 4;

sub init {

  my $class  = shift;
  my $self   = {};
  my %params = @_;

  $self->{params} = \%params;

  # Force INFO logger level
  $self->{params}->{level}    ||= 'INFO';
  $self->{params}->{category} ||= caller(0);

  bless $self, $class;
  return $self;

}

sub get_logger {

  my $self = shift;
  my ($category) = @_;
  my $params = $self->{params};

  return Slackware::SlackMan::Logger->init( 'file' => $params->{file}, 'category' => $category, 'level' => $params->{level} );

}

sub log {

  my $self = shift;
  my ($level, $message) = @_;

  my $file         = $self->{params}->{file};
  my $logger_level = $self->{params}->{level};
  my $category     = $self->{params}->{category} || 'main';
  my $time         = Time::Piece->new();

  $category =~ s/::/./g;

  return unless ( eval(uc($level)) <= eval(uc($logger_level)) );

  unless(open(LOG, '>>', $file)) {
    open(LOG, '>&STDERR'); # Fallback to STDERR
  }

  print LOG sprintf("%s [%5s] %s [pid:%s] %s\n",
                      $time->datetime, uc($level), $category, $$, $message);

}

sub debug {

  my $self = shift;
  my ($message) = @_;

  $self->log('debug', $message);

}

sub info {

  my $self = shift;
  my ($message) = @_;

  $self->log('info', $message);

}

sub notice {

  my $self = shift;
  my ($message) = @_;

  $self->log('notice', $message);

}

sub warning {

  my $self = shift;
  my ($message) = @_;

  $self->log('warning', $message);

}

sub error {

  my $self = shift;
  my ($message) = @_;

  $self->log('error', $message);

}

sub critical {

  my $self = shift;
  my ($message) = @_;

  $self->log('critical', $message);

}

sub alert {

  my $self = shift;
  my ($message) = @_;

  $self->log('alert', $message);

}

sub emergency {

  my $self = shift;
  my ($message) = @_;

  $self->log('emergency', $message);

}

1;
__END__

=head1 NAME

Slackware::SlackMan::Logger - SlackMan Logger module

=head1 SYNOPSIS

  use Slackware::SlackMan::Logger qw(:all);

  my $logger = Slackware::Slackman::Logger::new('file' => '/tmp/foo.log');
  $logger->info('FOO');

=head1 DESCRIPTION

Logger module for SlackMan (RFC 5424 compliant).

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 Slackware::SlackMan::Logger::new(%options)

=head1 METHODS

=head2 Slackware::SlackMan::Logger->log($level, $message)

=head2 Slackware::SlackMan::Logger->debug($message)

=head2 Slackware::SlackMan::Logger->info($message)

=head2 Slackware::SlackMan::Logger->notice($message)

=head2 Slackware::SlackMan::Logger->warning($message)

=head2 Slackware::SlackMan::Logger->error($message)

=head2 Slackware::SlackMan::Logger->critical($message)

=head2 Slackware::SlackMan::Logger->alert($message)

=head2 Slackware::SlackMan::Logger->emergency($message)

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Logger

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

