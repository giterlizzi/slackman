#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {

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
