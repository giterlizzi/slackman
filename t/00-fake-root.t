#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy;

my $current_directory  = dirname(__FILE__);
my $fakeroot_directory = "$current_directory/root";

my @directories = qw(
  /etc/slackman
  /etc/slackman/repos.d
  /var/lib/slackman
  /var/log
  /var/lock
  /var/cache/slackman
  /var/log/packages
  /var/log/removed_packages
);

foreach (@directories) {
  ok(make_path("$fakeroot_directory/$_"), "Create fakeroot directory $_");
}

ok(open(FH, '>', "$fakeroot_directory/etc/slackware-version"), 'Create slackware-version file');

print FH "Slackware 14.2\n";
close (FH);

ok(copy("$current_directory/../etc/slackman.conf", "$fakeroot_directory/etc/slackman/slackman.conf"), 'Copy default slackman.conf');
ok(copy("$current_directory/../etc/repos.d/slackware.repo", "$fakeroot_directory/etc/slackman/repos.d/slackware.repo"), 'Copy slackware.repo configurations');

done_testing();
