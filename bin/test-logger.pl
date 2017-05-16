#!/usr/bin/perl

use strict;
use warnings;

use 5.010;

use File::Basename;
use lib dirname(__FILE__)."/../lib";

use Slackware::SlackMan::Logger;


my $logger = Slackware::SlackMan::Logger->new( file => '/tmp/foo.log', level => 'INFO' );

$logger->debug('test');
$logger->info('test');
$logger->error('test');