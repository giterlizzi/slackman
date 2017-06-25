package Slackware::SlackMan::Config;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta3';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    %slackman_conf
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::Utils qw(:all);

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

my $config_file = "$root/etc/slackman/slackman.conf";
   $config_file = $option_config if ($option_config);
   $config_file =~ s|^//|/|;

if ($root ne '' && ! -d $root) {
  print "Slackware root directory $root not exists!\n";
  exit(255);
}

unless (-f $config_file) {
  print "Configuration file $config_file not found!\n";
  exit(255);
}

our %slackman_conf = read_config($config_file);

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

