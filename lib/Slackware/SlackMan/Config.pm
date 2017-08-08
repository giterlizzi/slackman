package Slackware::SlackMan::Config;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.1.0_11';
  @ISA     = qw(Exporter);

  @EXPORT = qw{
    %slackman_conf
  };

  @EXPORT_OK = qw(
    read_config
    set_config
    load_config
    stringify_config
    parse_config
  );

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;

sub load_config {

  # Set ROOT environment variable for Slackware pkgtools
  $ENV{ROOT} = $slackman_opts->{'root'} if ($slackman_opts->{'root'});

  # Set root directory for SlackMan (configuration, database, etc)
  my $root = '';
    $root = $ENV{ROOT} if($ENV{ROOT});

  my $config_file = "$root/etc/slackman/slackman.conf";
     $config_file = $slackman_opts->{'config'} if ($slackman_opts->{'config'});
     $config_file =~ s|^//|/|;

  if ($root ne '' && ! -d $root) {
    print "Slackware root directory '$root' not exists!\n";
    exit(255);
  }

  unless (-f $config_file) {
    print "Configuration file '$config_file' not found!\n";
    exit(255);
  }

  my %slackman_conf = read_config($config_file);

  # Set default slackman directories
  $slackman_conf{'directory'}->{'root'}  ||= $root;
  $slackman_conf{'directory'}->{'conf'}  ||= "$root/etc/slackman";
  $slackman_conf{'directory'}->{'log'}   ||= "$root/var/log";
  $slackman_conf{'directory'}->{'lib'}   ||= "$root/var/lib/slackman";
  $slackman_conf{'directory'}->{'cache'} ||= "$root/var/cache/slackman";
  $slackman_conf{'directory'}->{'lock'}  ||= "$root/var/lock";

  # Set default logger values
  $slackman_conf{'logger'}->{'level'} ||= 'debug';
  $slackman_conf{'logger'}->{'file'}  ||= $slackman_conf{'directory'}->{'log'} . '/slackman.log';

  # Set default value for color output
  $slackman_conf{'main'}->{'color'} ||= 'always';

  # Verify terminal color capability using tput(1) utility
  if ($slackman_conf{'main'}->{'color'} eq 'auto') {
    qx { tput colors > /dev/null 2>&1 };
    $ENV{ANSI_COLORS_DISABLED} = 1 if ( $? > 0 );
  }

  # Set config file location
  $slackman_conf{'config'}->{'file'} = $config_file;

  return %slackman_conf;

}

sub parse_config {

  my ($config_string) = @_;

  my @lines = split(/\n/, $config_string);

  my $section;
  my %config;

  foreach my $line (@lines) {

    chomp($line);

    # skip comments
    next if ($line =~ /^\s*#/);

    # skip empty lines
    next if ($line =~ /^\s*$/);

    if ($line =~ /^\[(.*)\]\s*$/) {
      $section = $1;
      next;
    }

    if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/) {

      my ($field, $value) = ($1, $2);

      if (not defined $section) {

        $value = 1 if ($value =~ /^(yes|true)$/);
        $value = 0 if ($value =~ /^(no|false)$/);

        $config{$field} = $value;
        next;

      }

      $value = 1 if ($value =~ /^(yes|true)$/);
      $value = 0 if ($value =~ /^(no|false)$/);

      $config{$section}{$field} = $value;

    }
  }

  return %config;

}

sub read_config {

  my ($file) = @_;

  open(CONFIG, "<$file") or die("Can't open config file; $?");

  my $config_string = do {
    local $/ = undef;
    <CONFIG>
  };

  close(CONFIG);

  my %config = parse_config($config_string);

  return %config;

}

sub stringify_config {

  my (%config) = @_;

  my $ini_string = '';

  foreach my $section (keys %config) {

    $ini_string .= sprintf("\n[%s]\n", $section);

    foreach my $key (keys %{ $config{$section} }) {
      $ini_string .= sprintf("%s = %s\n", $key, $config{$section}{$key});
    }

  }

  $ini_string =~ s/^\n//;

  return $ini_string;

}

sub set_config {

  my ( $input, $section, $param, $new_value ) = @_;

  my $current_section = '';
  my @lines  = split(/\n/, $input);
  my $output = '';

  foreach (@lines) {

    #if ( $_ =~ m/^\s*([^=]*?)\s*$/ ) {
    if ( $_ =~ /^(\[.*\])$/ ) {

      $current_section = $1;

    } elsif ( $current_section eq $section )  {

      my ( $key, $value ) = ( $_ =~ m/^\s*([^=]*[^\s=])\s*=\s*(.*?\S)\s*$/);

      if ( $key and $key eq $param  ) { 
        $output .= "$param = $new_value\n";
        next;
      }

    }

    $output .= "$_\n";

  }

  return $output;

}


1;
__END__

=head1 NAME

Slackware::SlackMan::Config - SlackMan Config module

=head1 SYNOPSIS

  use Slackware::SlackMan::Config qw(:all);

  my $config = read_config('foo.conf');

=head1 DESCRIPTION

Config module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 read_config

=head2 set_config

=head2 load_config

=head1 VARIABLES

=head2 $slackman_conf

  my $cache_directory = $slackman_conf->{'directory'}->{'cache'};

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Config

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

