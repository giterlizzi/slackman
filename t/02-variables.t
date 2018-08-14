#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;

my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

use_ok('Slackware::SlackMan::Utils');
use_ok('Slackware::SlackMan::Repo');
use_ok('Slackware::SlackMan::Parser');

my $arch = Slackware::SlackMan::Utils::get_arch();

my @variables = (
  [ '$release',      '14.2' ],
  [ '$release.real', '14.2' ],
  [ '$arch',         $arch  ],
);

foreach (@variables) {

  my $variable = $_->[0];
  my $expected = $_->[1];
  my $parsed   = Slackware::SlackMan::Parser::parse_variables( $variable );

  is ( $parsed, $expected,
       sprintf('Variable %s expected %s got %s', $variable, $expected, $parsed) );

}

done_testing();
