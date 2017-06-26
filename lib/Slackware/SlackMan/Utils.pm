package Slackware::SlackMan::Utils;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta4';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw(

    callback_spinner
    callback_status
    changelog_date_to_time
    confirm
    create_lock
    curl_cmd
    delete_lock
    directory_files
    download_file
    file_append
    file_handler
    file_read
    file_read_url
    file_write
    get_arch
    get_conf
    get_option
    get_options
    get_last_modified
    get_lock_pid
    get_slackware_release
    gpg_import_key
    gpg_verify
    ldd
    logger
    md5_check
    read_config
    set_config
    time_to_timestamp
    trim
    uniq
    w3c_date_to_time

    $slackman_opts

  );

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Term::ReadLine;
use POSIX ();
use Time::Local;
use IO::Dir;
use IO::Handle;
use Digest::MD5;
use Time::Piece;
use Getopt::Long qw(:config);

use Slackware::SlackMan::Logger;

my $curl_useragent    = "SlackMan/$VERSION";
my $curl_global_flags = qq/-H "User-Agent: $curl_useragent" -C - -L -k --fail --retry 5 --retry-max-time 0/;

my $logger;

# Prevent Insecure $ENV{PATH} while running with -T switch
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';

our $slackman_opts = {};

GetOptions( $slackman_opts,
            'help|h', 'man', 'version', 'root=s', 'repo=s', 'exclude|x=s',
            'limit=i', 'yes|y', 'no|n', 'quiet', 'no-excludes', 'no-priority',
            'config=s', 'force|f', 'download-only', 'new-packages', 'no-deps',
            'obsolete-packages', 'summary', 'show-files', 'exclude-installed' );

# Set default options
$slackman_opts->{'limit'} ||= 25;

# Get proxy flags for cURL
#
sub _get_curl_proxy_flags {

  my $proxy_conf = get_conf('proxy');

  return '' unless ($proxy_conf->{'enable'});

  my $curl_proxy_flags = '';

  if ($proxy_conf->{'username'}) {

    $curl_proxy_flags .= sprintf(" -x %s://%s:%s@%s:%s",
      $proxy_conf->{'protocol'},
      $proxy_conf->{'username'},
      $proxy_conf->{'password'},
      $proxy_conf->{'hostname'},
      $proxy_conf->{'port'},
    );

  } else {
    $curl_proxy_flags .= sprintf(" -x %s://%s:%s",
      $proxy_conf->{'protocol'},
      $proxy_conf->{'hostname'},
      $proxy_conf->{'port'},
    );
  }

  return $curl_proxy_flags;

}

# Get SlackMan config
#
sub get_conf {

  my ($key) = @_;

  return %Slackware::SlackMan::Config::slackman_conf unless ($key);
  return $Slackware::SlackMan::Config::slackman_conf{$key};

}

sub get_options {
  return $slackman_opts;
}

sub get_option {
  my ($option) = @_;
  return $slackman_opts->{$option} || undef;
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub ldd {

  my ($file) = @_;

  return sort { $a cmp $b }
          map { (abs_path($_) || $_) }
          map { $_ =~ m/(\/\S+)/ }
              ( split( /=>|\n/, qx(ldd $file 2>/dev/null) ) );

}

sub file_read {

  my ($filename) = @_;

  my $content = do {
    my $fh = file_handler($filename, '<');
    local $/ = undef;
    <$fh>
  };

  return $content;

}

sub file_write {

  my ($filename, $content) = @_;

  my $fh = file_handler($filename, '>');
  print $fh $content;
  close($fh);

  return;

}

sub file_append {

  my ($filename, $content, $autoflush) = @_;

  my $fh = file_handler($filename, '>>');
     $fh->autoflush(1) if ($autoflush);

  print $fh $content;
  close($fh);

  return;

}

sub file_handler {

  my ($filename, $mode) = @_;
  my $fh;

  open($fh, $mode, $filename) or die "Could not open '$filename': $!";
  return $fh;

}

sub curl_cmd {

  my ($curl_flags) = @_;

  my $curl_proxy_flags = _get_curl_proxy_flags() || '';
  my $curl_cmd = "curl $curl_global_flags $curl_proxy_flags $curl_flags";

  logger->debug("[CURL] $curl_cmd");

  return $curl_cmd;

}

sub download_file {

  my ($url, $output, $extra_curl_flags) = @_;

  $extra_curl_flags ||= '';

  my $curl_cmd = curl_cmd("$extra_curl_flags -# -o $output $url");

  logger->info("[CURL] Downloading $url");

  system($curl_cmd);
  return ($?) ? 0 : 1;

}

sub get_last_modified {

  my $url      = shift;
  my $curl_cmd = curl_cmd("-s -I $url");

  logger->debug(qq/[CURL] Get "Last-Modified" date of $url/);

  my $headers = qx{ $curl_cmd };
  my $result  = 0;

  if ($headers =~ m/Last\-Modified\:\s+(.*)/) {
    my $match = $1;
    return w3c_date_to_time(trim($match));
  }

  return $result;

}

sub trim {

  my $string = shift;
  return $string unless($string);

  $string =~ s/^\s+|\s+$//g;
  return $string;

}

sub confirm {

  my $prompt = shift;
  my $term   = Term::ReadLine->new('prompt');
  my $answer = undef;

  while ( defined ($_ = $term->readline($prompt)) ) {
    $answer = $_;
    last if ($answer =~ /^(y|n)$/i);
  }

  return 1 if ($answer =~ /y/i);
  return 0 if ($answer =~ /n/i);

}

sub changelog_date_to_time {

  my $timestamp = shift;
  return $timestamp unless($timestamp);

  $timestamp = trim($timestamp);

  if ($timestamp =~ /(UTC|CET|CEST|GMT)/) {

                 # Fri Jun 12 00:14:29 UTC 2015
    my $format = "%a %b %d %T $1 %Y";

    my $t = Time::Piece->strptime($timestamp, $format);
    return $t->epoch();

  } else {
                                              # Fri Jun 12 2015
    my $t = Time::Piece->strptime($timestamp, "%a %b %d %Y");
    return $t->epoch();

  }

}

sub w3c_date_to_time {

  my $timestamp = shift;
  return $timestamp unless($timestamp);

  $timestamp = trim($timestamp);
  $timestamp =~ s/\s+GMT//;  # Remove GMT to prevent issue with older Time::Piece
                             # NOTE: HTTP dates are always expressed in GMT, never in local time.

                                            # Wed, 12 Apr 2017 09:03:03 GMT
  my $t = Time::Piece->strptime($timestamp, "%a, %d %b %Y %H:%M:%S");

  return $t->epoch();

}

sub time_to_timestamp {

  my $time = shift;
  return $time unless($time);

  $time = trim($time);

  my $t = Time::Piece->new($time);
  return sprintf("%s %s", $t->ymd, $t->hms);

}

sub callback_status {
  STDOUT->printflush(sprintf("%s... ", shift));
}

sub callback_spinner {

  my $num     = shift;
  my @spinner = ('|','/','-','\\');

  $| = 1;

  STDOUT->printflush(sprintf("%s\b", $spinner[$num%4]));

}

sub gpg_verify {

  my $file = shift;

  logger->debug(qq/[GPG] verify file "$file" width "$file.asc"/);

  system("gpg --verify $file.asc $file 2>/dev/null");
  return ($?) ? 0 : 1;

}

sub gpg_import_key {

  my $key_file     = shift;
  my $key_contents = file_read($key_file);
     $key_contents =~ /uid\s+(.*)/;
  my $key_uid      = $1;

  logger->debug(qq/[GPG] Import key file with "$key_uid" uid/);

  system("/usr/bin/gpg --yes --batch --delete-key '$key_uid' &>/dev/null") if ($key_uid);
  system("/usr/bin/gpg --import $key_file &>/dev/null");

}

sub get_arch {
  return (POSIX::uname())[4];
}

sub get_slackware_release {

  my $slackware_version_file = get_conf('directory')->{'root'} . '/etc/slackware-version';
  my $slackware_version      = file_read($slackware_version_file);

  chomp($slackware_version);

  $slackware_version =~ /Slackware (.*)/;
  return $1;

}

sub md5_check {

  my ($file, $checksum) = @_;

  my $md5 = Digest::MD5->new;
  my $file_checksum = $md5->addfile(new IO::File("$file", "r"))->hexdigest;

  return 1 if ($checksum eq $file_checksum);
  return 0;

}

sub logger {

  my $logger_conf = get_conf('logger');

  $logger ||= Slackware::SlackMan::Logger->new( 'file'  => $logger_conf->{'file'},
                                                'level' => $logger_conf->{'level'} );
  return $logger;

}

sub create_lock {

  my $pid = $$;
  my $lock_file = get_conf('directory')->{'lock'} . '/slackman';

  file_write($lock_file, $pid);

}

sub get_lock_pid {

  my $lock_file = get_conf('directory')->{'lock'} . '/slackman';

  open(my $fh, '<', $lock_file) or return undef;
  chomp(my $pid = <$fh>);
  close($fh);

  # Verify slackman PID process
  unless (qx{ ps aux | grep -v grep | grep slackman | grep $pid }) {
    return undef;
  }

  return $pid;

}

sub delete_lock {

  my $lock_file = get_conf('directory')->{'lock'} . '/slackman';
  unlink($lock_file);

}

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
        $output .= "$keyname = $new_value\n";
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

Slackware::SlackMan::Utils - SlackMan utility module

=head1 SYNOPSIS

  use Slackware::SlackMan::Utils qw(:all);

  my $content = file_read('/etc/slackware-version');

=head1 DESCRIPTION

Config module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Utils

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

