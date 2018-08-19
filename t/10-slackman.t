#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;

use IPC::Open3;

my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

my $slackman_cmd = $current_directory . '/../blib/script/slackman';
my $pid = -1;

$pid = open3 'WRITE', 'READ', 'ERROR', $slackman_cmd;
cmp_ok($pid, '!=', 0, "Check 'slackman' PID");

# $pid = open3 'WRITE', 'READ', 'ERROR', 'sudo', $slackman_cmd, '--version';
# cmp_ok($pid, '!=', 0, "Check 'slackman --version' PID");
# 
# like(scalar <READ>, qr/^SlackMan - Slackware Package Manager v(\d)\.(\d)\.(\d)$/, "Check 'slackman --version' output");

done_testing();
