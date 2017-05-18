#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $current_directory  = dirname(__FILE__);
my $fakeroot_directory = "$current_directory/root";

ok(remove_tree($fakeroot_directory), "Remove fakeroot directory");

done_testing();
