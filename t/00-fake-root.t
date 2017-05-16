#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy;

my $current_directory = dirname(__FILE__);

my @fakeroot = qw(
  root/etc/slackman
  root/etc/slackman/repos.d
  root/var/lib/slackman
  root/var/log
  root/var/cache/slackman
  root/var/log/packages
  root/var/log/removed_packages
);

foreach (@fakeroot) {
  ok(make_path("$current_directory/$_"), "Create fakeroot directory $_");
}

ok(copy("$current_directory/../etc/slackman.conf", "$current_directory/root/etc/slackman/slackman.conf"), "Copy default slackman.conf");
ok(copy("$current_directory/../etc/repos.d/slackware.repo", "$current_directory/root/etc/slackman/repos.d/slackware.repo"), "Copy slackware.repo configurations");

done_testing();
