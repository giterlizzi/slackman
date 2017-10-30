#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Basename;

# Use slackman-libsupport libraries if available
use lib '/usr/share/slackman-libsupport/lib';

plan tests => 8;

BEGIN {

  my $current_directory = dirname(__FILE__);
  $ENV{ROOT} = "$current_directory/root";

  use_ok( 'Slackware::SlackMan' );
  use_ok( 'Slackware::SlackMan::Utils' );
  use_ok( 'Slackware::SlackMan::Package' );
  use_ok( 'Slackware::SlackMan::Config' );
  use_ok( 'Slackware::SlackMan::DB' );
  use_ok( 'Slackware::SlackMan::Parser' );
  use_ok( 'Slackware::SlackMan::Repo' );
  use_ok( 'Slackware::SlackMan::Command' );

}

diag( "Testing Slackware::SlackMan $Slackware::SlackMan::VERSION, Perl $], $^X" );

done_testing(8);
