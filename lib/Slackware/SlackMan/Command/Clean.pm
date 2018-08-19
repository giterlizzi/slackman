package Slackware::SlackMan::Command::Clean;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.4.0';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB    qw(:all);
use Slackware::SlackMan::Utils qw(:all);

use File::Path      qw(make_path remove_tree);
use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {

  'help.clean'      => \&call_clean_help,
  'clean'           => \&call_clean_help,
  'clean.help'      => \&call_clean_help,

  'clean.removed'   => \&call_clean_removed,
  'clean.cache'     => \&call_clean_cache,
  'clean.db'        => \&call_clean_db,
  'clean.metadata'  => \&call_clean_metadata,
  'clean.all'       => \&call_clean_all,

};

use constant COMMANDS_MAN => {
  'clean' => \&call_clean_man
};

use constant COMMANDS_HELP => {
  'clean' => \&call_clean_help
};

sub call_clean_man {

 pod2usage(
    -input   => __FILE__,
    -exitval => 0,
    -verbose => 2
  );

}

sub call_clean_help {

  pod2usage(
    -input    => __FILE__,
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}

sub call_clean_all {

  call_clean_db();
  call_clean_cache();

  exit(0);

}

sub call_clean_removed {

  my $slackware_removed_packages_dir = $slackman_conf->{'pkgtools'}->{'removed-packages'};
  my $slackware_removed_scripts_dir  = $slackman_conf->{'pkgtools'}->{'removed-scripts'};

  exit(0) unless(confirm("Do you want remove Slackware log files placed in $slackware_removed_packages_dir and $slackware_removed_scripts_dir ? [Y/N]"));

  logger->debug(qq/Delete removed packages in "$slackware_removed_packages_dir"/);

  STDOUT->printflush("\nDelete removed packages in $slackware_removed_packages_dir... ");
  unlink glob "$slackware_removed_packages_dir/*";
  STDOUT->printflush(colored("done\n", 'green'));

  logger->debug(qq/Delete removed scripts in "$slackware_removed_scripts_dir"/);

  STDOUT->printflush("\nDelete removed scripts in $slackware_removed_scripts_dir... ");
  unlink glob "$slackware_removed_scripts_dir/*";
  STDOUT->printflush(colored("done\n", 'green'));

}

sub call_clean_db {

  my $lib_dir = $slackman_conf->{'directory'}->{'lib'};
  my $db_file = "$lib_dir/db.sqlite";

  logger->debug(qq/Clear database file "$db_file"/);

  STDOUT->printflush("\nClear database... ");
  unlink($db_file) or warn("Unable to delete file: $!");
  STDOUT->printflush(colored("done\n", 'green'));

}

sub call_clean_cache {

  my $cache_dir = $slackman_conf->{'directory'}->{'cache'};
  logger->debug(qq/Clear packages cache directory "$cache_dir"/);

  STDOUT->printflush("\nClean packages download cache... ");
  remove_tree($cache_dir, { keep_root => 1 });
  STDOUT->printflush(colored("done\n", 'green'));


}

sub call_clean_metadata {

  my ($table) = @_;

  STDOUT->printflush("\nClean database metadata... ");

  db_wipe_tables();

  db_reindex();
  db_compact();

  STDOUT->printflush(colored("done\n", 'green'));

}

1;
__END__
=head1 NAME

slackman-clean - Clean and control SlackMan cache

=head1 SYNOPSIS

  slackman clean cache
  slackman clean metadata
  slackman clean db
  slackman clean removed
  slackman clean all
  slackman clean help

=head1 DESCRIPTION

B<slackman clean> clean and control SlackMan cache.

=head1 COMMANDS

  slackman clean cache       Clean cache package download directory
  slackman clean metadata    Clean database metadata (packages, changelog, manifest)
  slackman clean db          Clean database file
  slackman clean removed     Delete Slackware removed packages and scripts log from pkgtools log directory
  slackman clean all         Clean database file and cache directory
  slackman clean help        Display clean command help usage

=head1 OPTIONS

  -h, --help                   Display help and exit
  --man                        Display man pages
  --version                    Display version information
  -c, --config=FILE            Configuration file
  --color=[always|auto|never]  Colorize the output

=head1 SEE ALSO

L<slackman(8)>, L<slackman.conf(5)>

=head1 BUGS

Please report any bugs or feature requests to 
L<https://github.com/LotarProject/slackman/issues> page.

=head1 AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2018 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
