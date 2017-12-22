package Slackware::SlackMan;

use strict;
use warnings FATAL => 'all';

use 5.010;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  @ISA = qw(Exporter);

  $VERSION   = 'v1.3.0';
  @EXPORT_OK = ();
  @EXPORT    = qw(
    $slackman_opts
    $slackman_conf
    logger
  );

  %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
  );

}

use Carp 'confess';

# Load base modules
use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Logger;

# Initialize the global variables
our $slackman_conf = {};
our $slackman_opts = {};

use Getopt::Long qw(:config pass_through);

GetOptions( $slackman_opts,
  'config=s',
  'root=s',
);


# Set default options
$slackman_opts->{'limit'} ||= 25;

# FIX "Can't locate Term/ReadLine/Perl.pm [...]" message
$ENV{PERL_RL} = 'Stub';

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

# Load configuration file and save config hash
$slackman_conf = get_config($config_file);

# Set default slackman directories
$slackman_conf->{'directory'}->{'root'}    ||= $root;
$slackman_conf->{'directory'}->{'conf'}    ||= "$root/etc/slackman";
$slackman_conf->{'directory'}->{'repos'}   ||= "$root/etc/slackman/repos.d";
$slackman_conf->{'directory'}->{'renames'} ||= "$root/etc/slackman/renames.d";
$slackman_conf->{'directory'}->{'log'}     ||= "$root/var/log";
$slackman_conf->{'directory'}->{'lib'}     ||= "$root/var/lib/slackman";
$slackman_conf->{'directory'}->{'cache'}   ||= "$root/var/cache/slackman";
$slackman_conf->{'directory'}->{'lock'}    ||= "$root/var/lock";

# Set default logger values
$slackman_conf->{'logger'}->{'level'}      ||= 'debug';
$slackman_conf->{'logger'}->{'file'}       ||= $slackman_conf->{'directory'}->{'log'} . '/slackman.log';
$slackman_conf->{'logger'}->{'category'}   ||= '';

# Set default value for color output
$slackman_conf->{'main'}->{'color'} ||= 'always';

# Verify terminal color capability using tput(1) utility
if ($slackman_conf->{'main'}->{'color'} eq 'auto') {
  qx { tput colors > /dev/null 2>&1 };
  $ENV{ANSI_COLORS_DISABLED} = 1 if ( $? > 0 );
}

# Set config file location
$slackman_conf->{'config'}->{'file'} = $config_file;

# Set default renames
$slackman_conf->{'renames'} = ();

# Collect renames config files
if ( -d $slackman_conf->{'directory'}->{'renames'} ) {

  my %global_renames = ();

  my @renames_files = grep { -f } glob(sprintf('%s/*.renames', $slackman_conf->{'directory'}->{'renames'}));

  foreach my $renames_file (@renames_files) {

    my $local_renames = get_config($renames_file);

    foreach ( keys %{$local_renames} ) {
      $global_renames{$_} = $local_renames->{$_};
    }

  }

  $slackman_conf->{'renames'} = \%global_renames;

}

my $logger_conf = $slackman_conf->{'logger'};

my $caller = (caller(0))[3];

our $logger = Slackware::SlackMan::Logger->new( 'file'     => $logger_conf->{'file'},
                                                'level'    => $logger_conf->{'level'},
                                                'category' => $caller );

# "die" signal trap
$SIG{'__DIE__'} = sub {
  $logger->error(@_);
  confess(@_);
};

# "warn" signal trap
$SIG{'__WARN__'} = sub {
  $logger->warning(@_);
};

sub logger {
  return $logger->get_logger(caller(0));
}

1;

__END__

=head1 NAME

Slackware::SlackMan - SlackMan Core module

=head1 SYNOPSIS

  use Slackware::SlackMan qw(:package);

  my $pkg_info = get_package_info('aaa_base-14.2-x86_64-1.tgz');

=head1 DESCRIPTION

Core module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan

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
