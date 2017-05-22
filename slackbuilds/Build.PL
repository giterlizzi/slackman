#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use JSON::PP;
use Cwd;

unless ($< == 0) {
  warn "\nRequire root!\n";
  exit(1);
}

my $github_release = qx { curl https://api.github.com/repos/LotarProject/slackman/releases/latest 2> /dev/null };
   $github_release = decode_json($github_release);

my $cwd       = getcwd;
my $tag_name  = $github_release->{'tag_name'};
my ($version) = $tag_name =~ /^v(.*)/;

qx { curl -o $cwd/slackman/slackman-$version.tar.gz https://codeload.github.com/LotarProject/slackman/tar.gz/$tag_name };

$ENV{VERSION} = $version;
$ENV{OUTPUT}  = $cwd;

qx { ( cd $cwd/slackman; sh -x slackman.SlackBuild ) };

unlink("$cwd/slackman/slackman-$version.tar.gz");

exit(0);
