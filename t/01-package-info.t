#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;

use lib '/usr/share/slackman/lib';

my $current_directory = dirname(__FILE__);
$ENV{ROOT} = "$current_directory/root";

use_ok('Slackware::SlackMan::Utils');

my @pkg_data = (
  {
    'package'  => 'aaa_base-14.2-x86_64-1.txz',
    'expected' => {
      'name' => 'aaa_base',
      'version' => '14.2',
      'arch'    => 'x86_64',
      'tag'     => '',
      'build'   => '1'
    }
  },
  {
    'package'  => 'linux-howtos-20160401-noarch-1.txz',
    'expected' => {
      'name' => 'linux-howtos',
      'version' => '20160401',
      'arch'    => 'noarch',
      'tag'     => '',
      'build'   => '1'
    }
  },
  {
    'package'  => 'komodo-ide-10.2.0-x86_64-1_SBo.tgz',
    'expected' => {
      'name' => 'komodo-ide',
      'version' => '10.2.0',
      'arch'    => 'x86_64',
      'tag'     => 'SBo',
      'build'   => '1'
    }
  }
);

foreach my $pkg_data (@pkg_data) {

  my $pkg_info = Slackware::SlackMan::Utils::get_package_info($pkg_data->{'package'});

  foreach my $key (keys %{$pkg_data->{'expected'}}) {
    is ( $pkg_info->{$key},
         $pkg_data->{'expected'}->{$key},
         sprintf('[%s] Expected %s %s got %s', $pkg_data->{'package'}, $pkg_data->{'expected'}->{$key}, $key, $pkg_info->{$key}) );
  }

}

done_testing();
