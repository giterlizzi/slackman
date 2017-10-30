#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;

# Use slackman-libsupport libraries if available
use lib '/usr/share/slackman-libsupport/lib';

my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

use_ok( 'Slackware::SlackMan' );

like ( $Slackware::SlackMan::VERSION, qr/v(\d)\.(\d)\.(\d)/, 'Test SlackMan version' );

done_testing();

diag( "Testing Slackware::SlackMan $Slackware::SlackMan::VERSION, Perl $], $^X" );
