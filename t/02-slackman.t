#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Trap;
use File::Basename;


my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

use_ok( 'Slackware::SlackMan::Command' );

trap { Slackware::SlackMan::Command::run() };
is   ( $trap->exit,   0, 'Expecting "slackman" to exit with 0');
like ( $trap->stdout, qr/Slackware Package Manager/, 'Expecting "Slackware Package Manager" with STDOUT');
is   ( $trap->stderr, '', 'Expecting "slackman update" with no STDERR');

done_testing();
