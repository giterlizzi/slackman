package Slackware::SlackMan::Command::Clean;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.3.0';
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
  slackman clean all
  slackman clean help

=head1 DESCRIPTION

B<slackman clean> clean and control SlackMan cache.

=head1 COMMANDS

  slackman clean cache       Clean cache package download directory
  slackman clean metadata    Clean database metadata (packages, changelog, manifest)
  slackman clean db          Clean database file
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

Copyright 2016-2017 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
