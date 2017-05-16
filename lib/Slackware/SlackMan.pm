package Slackware::SlackMan;

use strict;
use warnings FATAL => 'all';

use 5.010;

use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Config  qw(:all);
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Repo    qw(:all);
use Slackware::SlackMan::Command qw(:all);

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  @ISA = qw(Exporter);

  $VERSION = 'v1.0.0';

  @EXPORT_OK = (
    @Slackware::SlackMan::Utils::EXPORT_OK,
    @Slackware::SlackMan::Package::EXPORT_OK,
    @Slackware::SlackMan::Config::EXPORT_OK,
    @Slackware::SlackMan::DB::EXPORT_OK,
    @Slackware::SlackMan::Parser::EXPORT_OK,
    @Slackware::SlackMan::Repo::EXPORT_OK,
    @Slackware::SlackMan::Command::EXPORT_OK,
    @Slackware::SlackMan::Logger::EXPORT_OK,
  );

  %EXPORT_TAGS = (
    'all'     => \@EXPORT_OK,
    'utils'   => \@Slackware::SlackMan::Utils::EXPORT_OK,
    'package' => \@Slackware::SlackMan::Package::EXPORT_OK,
    'config'  => \@Slackware::SlackMan::Config::EXPORT_OK,
    'db'      => \@Slackware::SlackMan::DB::EXPORT_OK,
    'parser'  => \@Slackware::SlackMan::Parser::EXPORT_OK,
    'repo'    => \@Slackware::SlackMan::Repo::EXPORT_OK,
    'command' => \@Slackware::SlackMan::Command::EXPORT_OK,
    'logger'  => \@Slackware::SlackMan::Logger::EXPORT_OK,
  );

}

1;
