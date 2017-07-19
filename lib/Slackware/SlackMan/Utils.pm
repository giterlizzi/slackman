package Slackware::SlackMan::Utils;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.1.0_08';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(

    callback_spinner
    callback_status
    changelog_date_to_time
    check_perl_module
    confirm
    confirm_choice
    create_lock
    curl_cmd
    datetime_calc
    delete_lock
    directory_files
    download_file
    file_append
    file_handler
    file_read
    file_read_url
    file_write
    filesize_h
    get_arch
    get_last_modified
    get_lock_pid
    get_slackware_release
    gpg_import_key
    gpg_verify
    ldd
    logger
    md5_check
    time_to_timestamp
    timestamp_to_time
    timestamp_options_to_sql
    trim
    uniq
    w3c_date_to_time

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
use Time::Seconds;

use Slackware::SlackMan;
use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Logger;

my $curl_useragent    = "SlackMan/$VERSION";
my $curl_global_flags = qq/-H "User-Agent: $curl_useragent" -C - -L -k --fail --retry 5 --retry-max-time 0/;

my $logger;

# Prevent Insecure $ENV{PATH} while running with -T switch
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';

# Get proxy flags for cURL
#
sub _get_curl_proxy_flags {

  my $proxy_conf = $slackman_conf{'proxy'};

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

sub filesize_h {

  my ($size, $decimal, $padding) = @_;

  $decimal ||= 0;
  $padding ||= 0;

  my @size_units = ('B', 'K', 'M', 'G', 'T');
  my $idx_unit   = 0;

  while ($size >= 1024 && ($idx_unit < scalar(@size_units) - 1)) {
    $size /= 1024;
    $idx_unit++;
  }

  my $size_h = sprintf('%.'.$decimal.'f %s', $size, $size_units[$idx_unit]);

  if ($padding) {
    return sprintf("%s$size_h", " "x(8 - length($size_h)));
  }

  return $size_h;

}

sub datetime_calc {

  my ($string) = @_;

  my ($sign, $digit, $order) = ($string =~ /^(\+|-|)(\d+)\s(days?|hours?|months?|years?)$/i);

  my $time = 0;

     $time = ONE_DAY   * $digit  if (lc($order) =~ /day/);
     $time = ONE_HOUR  * $digit  if (lc($order) =~ /hour/);
     $time = ONE_MONTH * $digit  if (lc($order) =~ /month/);
     $time = ONE_YEAR  * $digit  if (lc($order) =~ /year/);

  my $datetime = Time::Piece->new();

  if ($sign eq '' || $sign eq '+') {
    $datetime += $time;
  }
  if ($sign eq '-') {
    $datetime -= $time;
  }

  return $datetime;

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

  my ($url) = @_;

  if ($url =~ /^file/) {

    my $local_file = $url;
       $local_file =~ s/file:\/\///;

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
        $atime, $mtime, $ctime, $blksize, $blocks) = stat($local_file);

    return $mtime;

  }

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

  while ( defined ($_ = $term->readline("$prompt ")) ) {
    $answer = $_;
    last if ($answer =~ /^(y|n)$/i);
  }

  return 1 if ($answer =~ /y/i);
  return 0 if ($answer =~ /n/i);

}

sub confirm_choice {

  my ($prompt, $regex) = @_; 

  my $term   = Term::ReadLine->new('prompt');
  my $answer = undef;

  while ( defined ($_ = $term->readline("$prompt ")) ) {
    $answer = $_;
    last if ($answer =~ /^($regex)$/);
  }

  return uc($answer);

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

sub timestamp_to_time {

  my ($timestamp) = @_;

  my $t = Time::Piece->strptime($timestamp, "%Y-%m-%d %H:%M:%S");
  return $t->epoch;

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

sub timestamp_options_to_sql {

  my $option_after  = $slackman_opts->{'after'};
  my $option_before = $slackman_opts->{'before'};

  my $parsed_after  = undef;
  my $parsed_before = undef;

  my @timestamp_filter = ();

  if ($option_after) {

    if ($option_after && $option_after =~ /^(\+|-|)(\d+)\s(days?|months?|years?)$/) {
      $parsed_after  = datetime_calc($option_after)->ymd;
    }

    if (! $parsed_after && $option_after =~ /^\d{4}-\d{2}-\d{2}/) {
      $parsed_after = $option_after;
    }

    push(@timestamp_filter, sprintf('(timestamp > "%s")', $parsed_after))  if ($parsed_after);

  }

  if ($option_before) {

    if ($option_before && $option_before =~ /^(\+|-|)(\d+)\s(days?|months?|years?)$/) {
      $parsed_before = datetime_calc($option_before)->ymd;
    }

    if (! $parsed_before && $option_before =~ /^\d{4}-\d{2}-\d{2}/) {
      $parsed_before = $option_before;
    }

    push(@timestamp_filter, sprintf('(timestamp < "%s")', $parsed_before)) if ($parsed_before);

  }

  return sprintf('( %s )', join(' AND ', @timestamp_filter)) if ($parsed_after || $parsed_before);

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

  logger->debug(qq/[GPG] verify file "$file" with "$file.asc"/);

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

my $slackware_release;

sub _get_slackware_release {

  my $slackware_version_file = $slackman_conf{'directory'}->{'root'} . '/etc/slackware-version';
  my $slackware_version      = file_read($slackware_version_file);

  chomp($slackware_version);

  $slackware_version =~ /Slackware (.*)/;
  return $1;

}

sub get_slackware_release {
  return $slackware_release ||= _get_slackware_release(); # Reduce "open" system call
}

sub md5_check {

  my ($file, $checksum) = @_;

  my $md5 = Digest::MD5->new;
  my $file_checksum = $md5->addfile(new IO::File("$file", "r"))->hexdigest;

  return 1 if ($checksum eq $file_checksum);
  return 0;

}

sub check_perl_module {
  my ($module) = @_;
  return 1 if (eval "require $module");
  return 0;
}

sub logger {

  my $logger_conf = $slackman_conf{'logger'};

  $logger ||= Slackware::SlackMan::Logger->new( 'file'  => $logger_conf->{'file'},
                                                'level' => $logger_conf->{'level'} );
  return $logger;

}

sub create_lock {

  my $pid = $$;
  my $lock_file = $slackman_conf{'directory'}->{'lock'} . '/slackman';

  file_write($lock_file, $pid);

}

sub get_lock_pid {

  my $lock_file = $slackman_conf{'directory'}->{'lock'} . '/slackman';

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

  my $lock_file = $slackman_conf{'directory'}->{'lock'} . '/slackman';
  unlink($lock_file);

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

