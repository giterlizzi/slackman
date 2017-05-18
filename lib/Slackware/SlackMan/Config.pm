package Slackware::SlackMan::Config;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.0';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    read_config
    set_config
    $slackman_conf
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Data::Dumper;
use Slackware::SlackMan::Utils qw(:all);

sub read_config {

  my $file = shift;
  my $fh   = file_handler($file, '<');

  my $section;
  my %config;

  while (my $line = <$fh>) {

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

sub set_config {

  my ( $input, $section, $keyname, $new_value ) = @_;

  my $current_section = '';
  my @lines  = split(/\n/, $input);
  my $output = '';

  foreach (@lines) { 

    if ( $_ =~ m/^\s*([^=]*?)\s*$/ ) {
      $current_section = $1;

    } elsif ( $current_section eq $section )  {

      my ( $key, $value ) = ( $_ =~ m/^\s*([^=]*[^\s=])\s*=\s*(.*?\S)\s*$/);

      if ( $key and $key eq $keyname  ) { 
        $output .= "$keyname=$new_value\n";
        next;
      }

    }

    $output .= "$_\n";

  }

  return $output;

}

my $option_root   = undef;
my $option_config = undef;

{
  use Getopt::Long qw(:config pass_through);

  GetOptions(
    'root=s'     => \$option_root,
    'c|config=s' => \$option_config,
  );

}

# Set ROOT environment variable for Slackware pkgtools
$ENV{ROOT} = $option_root if ($option_root);

# Set root directory for SlackMan (configuration, database, etc)
my $root = '';
   $root = $ENV{ROOT} if($ENV{ROOT});

my $config_file    = "$root/etc/slackman/slackman.conf";
   $config_file    = $option_config if ($option_config);
   $config_file    =~ s|^//|/|;

if ($root ne '' && ! -d $root) {
  print "Slackware root directory $root not exists!\n";
  exit(255);
}

unless (-f $config_file) {
  print "Configuration file $config_file not found!\n";
  exit(255);
}

my %config         = read_config($config_file);
my $conf_main      = $config{main};
my $conf_proxy     = $config{proxy};
my $conf_slackware = $config{slackware};
my $conf_directory = $config{directory};
my $conf_logger    = $config{logger};

$conf_directory->{'root'}  ||= $root;
$conf_directory->{'conf'}  ||= "$root/etc/slackman";
$conf_directory->{'log'}   ||= "$root/var/log";
$conf_directory->{'lib'}   ||= "$root/var/lib/slackman";
$conf_directory->{'cache'} ||= "$root/var/cache/slackman";
$conf_directory->{'lock'}  ||= "$root/var/lock";

$conf_logger->{'level'} ||= 'debug';
$conf_logger->{'file'}  ||= $conf_directory->{'log'} . '/slackman.log';

our $slackman_conf = {
  'main'      => $conf_main,
  'proxy'     => $conf_proxy,
  'slackware' => $conf_slackware,
  'directory' => $conf_directory,
  'logger'    => $conf_logger,
};

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

