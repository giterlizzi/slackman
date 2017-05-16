package Slackware::SlackMan::Logger;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.0.0';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{}

}

use Data::Dumper;
use Slackware::SlackMan::Utils qw(:all);

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

sub new {

  my $class  = shift;
  my $self   = {};
  my %params = @_;

  $self->{params} = \%params;

  # Force INFO logger level
  $self->{params}->{level} ||= 'INFO';

  bless $self, $class;
  return $self;

}

sub log {

  my $self = shift;
  my ($level, $message) = @_;

  my $file         = $self->{params}->{file};
  my $logger_level = $self->{params}->{level};

  return unless ( eval(uc($level)) <= eval(uc($logger_level)) );

  file_append($file, sprintf("%s %s - %s\n", time_to_timestamp(time), uc($level), $message), 1);

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
