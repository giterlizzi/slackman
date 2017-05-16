package Slackware::SlackMan::Utils;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.0';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    callback_spinner
    callback_status
    changelog_date_to_time
    confirm
    directory_files
    download_file
    file_append
    file_handler
    file_read
    file_read_url
    file_write
    get_last_modified
    gpg_import_key
    gpg_verify
    time_to_timestamp
    trim
    w3c_date_to_time
    md5_check
    get_arch
    get_slackware_release
    logger
    create_lock
    get_lock_pid
    delete_lock
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Term::ReadLine;
use POSIX;
use Time::Local;
use IO::Dir;
use IO::Handle;
use Digest::MD5;
use Time::Piece;
use POSIX;

use Slackware::SlackMan::Logger;

my $curl_useragent    = "SlackMan/$VERSION";
my $curl_global_flags = qq/-H "User-Agent: $curl_useragent" -C - -L -k --fail --retry 5 --retry-max-time 0/;

if ($Slackware::SlackMan::Config::slackman_conf->{'proxy'}->{'enable'}) {

  my $proxy_conf = $Slackware::SlackMan::Config::slackman_conf->{'proxy'};

  if ($proxy_conf->{'username'}) {

    $curl_global_flags .= sprintf(" -x %s://%s:%s@%s:%s",
      $proxy_conf->{'protocol'},
      $proxy_conf->{'username'},
      $proxy_conf->{'password'},
      $proxy_conf->{'hostname'},
      $proxy_conf->{'port'},
    );

  } else {
    $curl_global_flags .= sprintf(" -x %s://%s:%s",
      $proxy_conf->{'protocol'},
      $proxy_conf->{'hostname'},
      $proxy_conf->{'port'},
    );
  }

}

my $logger;

# Prevent Insecure $ENV{PATH} while running with -T switch
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';

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

  open($fh, $mode.':encoding(UTF-8)', $filename) or die "Could not open '$filename': $!";
  return $fh;

}

sub file_read_url {

  my $url      = shift;
  my $curl_cmd = "curl $curl_global_flags -s $url";

  logger->info("Downloading $url");
  logger->debug("CURL: $curl_cmd");

  my $data = qx{ $curl_cmd };
  return $data;
}

sub download_file {

  my ($url, $output, $extra_curl_flags) = @_;

  my $curl_flags  = $curl_global_flags;
     $curl_flags .= " $extra_curl_flags" if ($extra_curl_flags);
  my $curl_cmd    = "curl $curl_flags -# -o $output $url";

  logger->info("Downloading $url");
  logger->debug("CURL: $curl_cmd");

  system($curl_cmd);
  return ($?) ? 0 : 1;

}

sub get_last_modified {

  my $url      = shift;
  my $curl_cmd = "curl $curl_global_flags -s -I $url";

  logger->debug(qq/Get "Last-Modified" date of $url/);
  logger->debug("CURL: $curl_cmd");

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

                                            # Wed, 12 Apr 2017 09:03:03 GMT
  my $t = Time::Piece->strptime($timestamp, "%a, %d %b %Y %H:%M:%S %Z");

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
  my $status = shift;
  STDOUT->printflush("$status... ");
}

sub callback_spinner {

  my $num     = shift;
  my @spinner = ('|','/','-','\\');

  $| = 1;

  STDOUT->printflush(sprintf("%s\b", $spinner[$num%4]));

}

sub gpg_verify {

  my $file = shift;

  logger->debug(qq/GPG: verify file "$file" width "$file.asc"/);

  system("gpg --verify $file.asc $file 2>/dev/null");
  return ($?) ? 0 : 1;

}

sub gpg_import_key {

  my $key_file     = shift;
  my $key_contents = file_read($key_file);
     $key_contents =~ /uid\s+(.*)/;
  my $key_uid      = $1;

  logger->debug(qq/GPG: Import key file with "$key_uid" uid/);

  system("/usr/bin/gpg --yes --batch --delete-key '$key_uid' &>/dev/null") if ($key_uid);
  system("/usr/bin/gpg --import $key_file &>/dev/null");

}

sub get_arch {
  return (POSIX::uname())[4];
}

sub get_slackware_release {

  my $slackware_version_file = $Slackware::SlackMan::Config::slackman_conf->{'directory'}->{'root'} . '/etc/slackware-version';
  my $slackware_version      = file_read($slackware_version_file);

  chomp($slackware_version);

  $slackware_version =~ /Slackware (.*)/;
  return $1;

}

sub md5_check {

  my ($file, $checksum) = @_;

  my $file_checksum = Digest::MD5->new->addfile(new IO::File("$file", "r"))->hexdigest;

  return 1 if ($checksum eq $file_checksum);
  return 0;

}

sub logger {

  my $logger_file  = $Slackware::SlackMan::Config::slackman_conf->{'logger'}->{'file'};
  my $logger_level = $Slackware::SlackMan::Config::slackman_conf->{'logger'}->{'level'};

  $logger ||= Slackware::SlackMan::Logger->new( 'file'  => $logger_file,
                                                'level' => $logger_level );
  return $logger;
}

sub create_lock {

  my $pid = $$;
  my $lock_file = $Slackware::SlackMan::Config::slackman_conf->{'directory'}->{'lock'} . '/slackman';

  file_write($lock_file, $pid);

}

sub get_lock_pid {

  my $lock_file = $Slackware::SlackMan::Config::slackman_conf->{'directory'}->{'lock'} . '/slackman';

  open(my $fh, '<', $lock_file) or return;
  chomp(my $pid = <$fh>);
  close($fh);

  # Verify slackman PID process
  unless (qx/ps aux | grep -v grep | grep slackman | grep $pid/) {
    return;
  }

  return $pid;

}

sub delete_lock {

  my $lock_file = $Slackware::SlackMan::Config::slackman_conf->{'directory'}->{'lock'} . '/slackman';
  unlink($lock_file);

}


1;
