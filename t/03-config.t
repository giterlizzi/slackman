#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;

my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

use_ok('Slackware::SlackMan::Config');

my $config_file = $ENV{ROOT} . '/etc/slackman/slackman.conf';

my $cfg = Slackware::SlackMan::Config->new($config_file);

is ( $cfg->get('logger.level'),           'info',  'Get logger.level value' );
is ( $cfg->set('logger.level', 'debug') , 'debug', 'Set logger.level to debug value' );
is ( $cfg->get('logger.level') ,          'debug', 'Get logger.level value' );

ok ( $cfg->save() , 'Save config file' );

done_testing();
