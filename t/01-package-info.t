#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 18;

use Slackware::SlackMan::Package qw{:all};

my $pkg_1 = 'aaa_base-14.2-x86_64-1.txz';
my $pkg_2 = 'linux-howtos-20160401-noarch-1.txz';
my $pkg_3 = 'komodo-ide-10.2.0-x86_64-1_SBo.tgz';

my $pkg_info_1 = package_info($pkg_1);
my $pkg_info_2 = package_info($pkg_2);
my $pkg_info_3 = package_info($pkg_3);

is ( $pkg_info_1->{'package'},  $pkg_1,         "Expected package: $pkg_1" );
is ( $pkg_info_1->{'name'},     'aaa_base',     'Expected name:    aaa_base' );
is ( $pkg_info_1->{'version'},  '14.2',         'Expected version: 14.2' );
is ( $pkg_info_1->{'arch'},     'x86_64',       'Expected arch:    x86_64' );
is ( $pkg_info_1->{'tag'},      '',             'Expected tag:     none' );
is ( $pkg_info_1->{'build'},    1,              'Expected build:   1' );

is ( $pkg_info_2->{'package'},  $pkg_2,         "Expected package: $pkg_2" );
is ( $pkg_info_2->{'name'},    'linux-howtos',  'Expected name:    linux-howtos' );
is ( $pkg_info_2->{'version'}, '20160401',      'Expected version: 20160401' );
is ( $pkg_info_2->{'arch'},    'noarch',        'Expected arch:    noarch' );
is ( $pkg_info_2->{'tag'},     '',              'Expected tag:     none' );
is ( $pkg_info_2->{'build'},   1,               'Expected build:   1' );

is ( $pkg_info_3->{'package'}, $pkg_3,          "Expected package: $pkg_3" );
is ( $pkg_info_3->{'name'},    'komodo-ide',    'Expected name:    komodo-ide' );
is ( $pkg_info_3->{'version'}, '10.2.0',        'Expected version: 10.2.0' );
is ( $pkg_info_3->{'arch'},    'x86_64',        'Expected arch:    x86_64' );
is ( $pkg_info_3->{'tag'},     'SBo',           'Expected tag:     SBo' );
is ( $pkg_info_3->{'build'},   1,               'Expected build:   1' );
