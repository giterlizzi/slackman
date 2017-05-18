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


@ARGV = ("update");

trap { Slackware::SlackMan::Command::run() };
is   ( $trap->exit,   0, 'Expecting "slackman update" to exit with 0');
like ( $trap->stdout, qr/done/, 'Expecting "slackman update" with STDOUT');
is   ( $trap->stderr, '', 'Expecting "slackman update" with no STDERR');

# @ARGV = ("list", "packages");
# 
# trap { Slackware::SlackMan::Command::run() };
# is   ( $trap->exit,   0, 'Expecting "slackman list packages" to exit with 0');
# like ( $trap->stdout, qr/aaa_base/, 'Expecting "slackman list packages" with "aaa_base" package');
# is   ( $trap->stderr, '', 'Expecting "slackman list packages" with no STDERR');
# 
# @ARGV = ("info", "aaa_base");
# 
# trap { Slackware::SlackMan::Command::run() };
# is   ( $trap->exit,   0, 'Expecting "slackman info aaa_base" to exit with 0');
# like ( $trap->stdout, qr/aaa_base/, 'Expecting "slackman info aaa_base" with "aaa_base" package info');
# is   ( $trap->stderr, '', 'Expecting "slackman info aaa_base" with no STDERR');

done_testing();
