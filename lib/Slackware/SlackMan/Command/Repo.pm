package Slackware::SlackMan::Command::Repo;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0_10';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB     qw(:all);
use Slackware::SlackMan::Repo   qw(:all);
use Slackware::SlackMan::Utils  qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;
use Pod::Find qw(pod_where);


use constant COMMANDS_DISPATCHER => {

  'help.repo'    => \&call_repo_help,
  'repo'         => \&call_repo_help,
  'repo.help'    => \&call_repo_help,

  'repo.disable' => \&call_repo_disable,
  'repo.enable'  => \&call_repo_enable,
  'repo.info'    => \&call_repo_info,
  'repo.list'    => \&call_repo_list,

};

use constant COMMANDS_MAN => {
  'repo' => \&call_repo_man
};

use constant COMMANDS_HELP => {
  'repo' => \&call_repo_help
};


sub call_repo_man {

 pod2usage(
    -input   => pod_where({-inc => 1}, __PACKAGE__),
    -exitval => 0,
    -verbose => 2
  );

}

sub call_repo_help {

  pod2usage(
    -input    => pod_where({-inc => 1}, __PACKAGE__),
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}

sub call_repo_list {

  my @repositories = get_repositories();

  print "\nAvailable repository\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-30s %-70s %-10s %-10s %-4s\n", "Repository ID",  "Description", "Status", "Priority", "Packages");
  print sprintf("%s\n", "-"x132);

  foreach my $repo_id (@repositories) {

    my $repo_info = get_repository($repo_id);
    my $num_pkgs  = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);

    print sprintf("%-30s %-70s %-10s %-10s %-4s\n",
      $repo_id,
      $repo_info->{name},
      ($repo_info->{enabled} ? colored(sprintf("%-10s", 'Enabled'), 'GREEN') : 'Disabled'),
      $repo_info->{priority},
      $num_pkgs
    );

  }

  exit(0);

}

sub call_repo_disable {

  my ($repo_id) = @_;

  if ($repo_id =~ /\*/) {

    foreach (get_enabled_repositories()) {
      if ($_ =~ /$repo_id/) {
        disable_repository($_);
        print sprintf("Repository '%s' disabled\n", $_);
      }
    }

    exit(0);

  }

  disable_repository($repo_id);
  print "Repository '$repo_id' disabled\n";

}

sub call_repo_enable {

  my ($repo_id) = @_;

  if ($repo_id =~ /\*/) {

    foreach (get_disabled_repositories()) {
      if ($_ =~ /$repo_id/) {
        enable_repository($_);
        print sprintf("Repository '%s' enabled\n", $_);
      }
    }

    print sprintf("\n%s: Remember to launch 'slackman update' command!\n", colored('NOTE', 'bold'));

    exit(0);

  }

  enable_repository($repo_id);
  print qq/Repository "$repo_id" enabled\n\n/;

  print sprintf("%s: Remember to launch 'slackman update --repo $repo_id' command!\n", colored('NOTE', 'bold'));

  exit(0);

}

sub call_repo_info {

  my ($repo_id) = @_;

  unless($repo_id) {
    print "Usage: slackman repo info REPOSITORY\n";
    exit(255);
  }

  my $repo_data = get_repository($repo_id);

  unless($repo_data) {
    print "Repository not found!\n";
    exit(255);
  }

  update_repo_data();

  my $package_nums = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);
  my $last_update  = time_to_timestamp(db_meta_get("last-update.$repo_id.packages"));

  my @urls = qw/changelog packages manifest checksums gpgkey/;

  print "\n";
  print sprintf("%-15s : %s\n",    "Name",          $repo_data->{name});
  print sprintf("%-15s : %s\n",    "ID",            $repo_data->{id});
  print sprintf("%-15s : %s\n",    "Configuration", $repo_data->{config_file});
  print sprintf("%-15s : %s\n",    "Mirror",        $repo_data->{mirror});
  print sprintf("%-15s : %s\n",    "Status",        (($repo_data->{enabled}) ? 'enabled' : 'disabled'));
  print sprintf("%-15s : %s\n",    "Last Update",   ($last_update || ''));
  print sprintf("%-15s : %s\n",    "Priority",      $repo_data->{priority});
  print sprintf("%-15s : %s\n",    "Packages",      $package_nums);
  print sprintf("%-15s : %s/%s\n", "Directory",     $slackman_conf{directory}->{cache}, $repo_data->{id});

  print "\nRepository URLs :\n";

  foreach (@urls) {
    next unless($repo_data->{$_});
    print sprintf("  * %-15s : %s\n", $_, $repo_data->{$_});
  }

  print "\n";

  exit(0);

}


1;
__END__
=head1 NAME

slackman-repo - Display and manage Slackware repository

=head1 SYNOPSIS

  slackman repo info REPOSITORY
  slackman repo enable REPOSITORY
  slackman repo disable REPOSITORY
  slackman repo list
  slackman repo help

=head1 DESCRIPTION

B<slackman repo> display and manage Slackware repository defined in F</etc/slackman/repod.d>
directory.

=head1 COMMANDS

  slackman repo list                   List available repositories
  slackman repo enable REPOSITORY      Enable repository
  slackman repo disable REPOSITORY     Disable repository
  slackman repo info REPOSITORY        Display repository information
  slackman repo help                   Display repo command help usage

=head1 OPTIONS

  -h, --help                           Display help and exit
  --man                                Display man pages
  --version                            Display version information
  -c, --config=FILE                    Configuration file
  --color=[always|auto|never]          Colorize the output

=head1 EXAMPLES

List all repositories:

  slackman repo list

  --------------------------------------------------------------------------------------
  Repository ID         Description                       Status     Priority   Packages
  --------------------------------------------------------------------------------------
  slackware:extra       Slackware64-current (Extra)       Enabled    0          92
  slackware:multilib    Slackware64-current (MultiLib)    Enabled    10         181
  slackware:packages    Slackware64-current               Enabled    0          1348
  slackware:pasture     Slackware64-current (Pasture)     Disabled   0          0
  slackware:patches     Slackware64-current (Patches)     Enabled    10         0
  slackware:testing     Slackware64-current (Testing)     Disabled   -1         0


Enable a repository:

  slackman repo enable slackware:multilib


Display repository informations:

  slackman repo info slackware:extra

  Name:                Slackware64-current (Extra)
  ID:                  slackware:extra
  Configuration:       /etc/slackman/repos.d/slackware.repo
  Mirror:              http://mirrors.slackware.com/slackware/slackware64-current/
  Status:              enabled
  Last Update:         2017-05-24 07:03:49
  Priority:            0
  Packages:            92
  
  Repository URLs:
    * packages         http://mirrors.slackware.com/slackware/slackware64-current/extra/PACKAGES.TXT
    * manifest         http://mirrors.slackware.com/slackware/slackware64-current/extra/MANIFEST.bz2
    * checksums        http://mirrors.slackware.com/slackware/slackware64-current/extra/CHECKSUMS.md5
    * gpgkey           http://mirrors.slackware.com/slackware/slackware64-current/GPG-KEY


=head1 FILES

=over

=item /etc/slackman/slackman.conf

=item /etc/slackman/repos.d/*

=back

=head1 SEE ALSO

L<slackman(8)>, L<slackman.conf(5)>, L<slackman.repo(5)>, L<slackman-update(8)>

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
