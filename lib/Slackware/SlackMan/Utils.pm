package Slackware::SlackMan::Utils;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.3.0';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(

    callback_spinner
    callback_status
    changelog_date_to_time
    check_perl_module
    confirm
    confirm_choice
    create_lock
    datetime_calc
    datetime_h
    dbus_notifications
    dbus_slackman
    delete_lock
    directory_files
    download_file
    failed_sign
    file_append
    file_handler
    file_read
    file_read_url
    file_write
    filesize_h
    str_pad
    table
    get_arch
    get_last_modified
    get_lock_pid
    get_package_info
    get_slackware_release
    gpg_import_key
    gpg_verify
    http_client
    http_date_to_time
    is_slackware_current
    ldd
    md5_check
    repo_option_to_sql
    success_sign
    terminal_width
    time_to_timestamp
    timestamp_options_to_sql
    timestamp_to_time
    trim
    uniq
    versioncmp

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
use Carp ();
use File::Basename;
use Term::ANSIColor qw(color colored :constants);
use HTTP::Tiny;

use Slackware::SlackMan;


# Prevent Insecure $ENV{PATH} while running with -T switch
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';


# HTTP Client
#
sub http_client {

  my %http_options = ( 'agent' => "SlackMan/$VERSION" );
  my $proxy_conf   = $slackman_conf->{'proxy'};

  if ($proxy_conf->{'enable'}) {

    my $proxy_url = undef;

    if ($proxy_conf->{'username'}) {

      $proxy_url = sprintf("%s://%s:%s@%s:%s",
        $proxy_conf->{'protocol'},
        $proxy_conf->{'username'},
        $proxy_conf->{'password'},
        $proxy_conf->{'hostname'},
        $proxy_conf->{'port'},
      );

    } else {

      $proxy_url = sprintf("%s://%s:%s",
        $proxy_conf->{'protocol'},
        $proxy_conf->{'hostname'},
        $proxy_conf->{'port'},
      );

    }

    $http_options{'http_proxy'}  = $proxy_url;
    $http_options{'https_proxy'} = $proxy_url;

  }

  my $http = HTTP::Tiny->new( %http_options );

  return $http;

}


# Progress bar
#
sub callback_progress_bar {

  my ( $text, $got, $total, $width, $char ) = @_;

  $| = 1;

  $width ||= 25;
  $char  ||= '=';

  my $got_h      = filesize_h($got, 1);
  my $total_h    = filesize_h($total, 1);
  my $num_width  = length $total_h;
  my $percentage = (100 * $got/+$total);

  return sprintf "%-72s %-8s  %3d%% [%-${width}s] %8s\r",
    $text, $total_h, $percentage, $char x (($width-1)*$got/$total) . '>',
    $got_h;

}


# SlackMan DBus interface
#
sub dbus_slackman {

  require Net::DBus;

  return Net::DBus->system
    ->get_service('org.lotarproject.SlackMan')
    ->get_object('/org/lotarproject/SlackMan');

}


# Notification DBus interface
#
sub dbus_notifications {

  require Net::DBus;

  return Net::DBus->session
    ->get_service('org.freedesktop.Notifications')
    ->get_object('/org/freedesktop/Notifications');

}


# Code from Sort::Versions module
#
sub versioncmp( $$ ) {

  my @A = ($_[0] =~ /([-.]|\d+|[^-.\d]+)/g);
  my @B = ($_[1] =~ /([-.]|\d+|[^-.\d]+)/g);

  my ($A, $B);

  while (@A and @B) {

    $A = shift @A;
    $B = shift @B;

    if ($A eq '-' and $B eq '-') {
      next;

    } elsif ( $A eq '-' ) {
      return -1;

    } elsif ( $B eq '-') {
      return 1;

    } elsif ($A eq '.' and $B eq '.') {
      next;

    } elsif ( $A eq '.' ) {
      return -1;

    } elsif ( $B eq '.' ) {
      return 1;

    } elsif ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
      if ($A =~ /^0/ || $B =~ /^0/) {
        return $A cmp $B if $A cmp $B;
      } else {
        return $A <=> $B if $A <=> $B;
      }

    } else {
      $A = uc $A;
      $B = uc $B;
      return $A cmp $B if $A cmp $B;
    }

  }

  @A <=> @B;

}


# Return unique values in array
#
sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}


# Return a list of libraries for specified binary file
#
sub ldd {

  my ($file) = @_;

  return sort { $a cmp $b }
          map { (abs_path($_) || $_) }
          map { $_ =~ m/(\/\S+)/ }
              ( split( /=>|\n/, qx(ldd $file 2>/dev/null) ) );

}


# Display datetime in human-readable format
#
sub datetime_h {

  my ($timestamp) = @_;

  my $ago = time() - $timestamp;

  if ($ago > 24 * 60 * 60 * 30 * 12 * 2) {
    return sprintf('%d years ago', ($ago / (24 * 60 * 60 * 30 * 12)));
  }

  if ($ago > 24 * 60 * 60 * 30 * 2) {
    return sprintf('%d months ago', ($ago / (24 * 60 * 60 * 30)));
  }

  if ($ago > 24 * 60 * 60 * 7 * 2) {
    return sprintf('%d weeks ago', ($ago / (24 * 60 * 60 * 7)));
  }

  if ($ago > 24 * 60 * 60 * 2) {
    return sprintf('%d days ago', ($ago / (24 * 60 * 60)));
  }

  if ($ago > 60 * 60 * 2) {
    return sprintf('%d hours ago', ($ago / (60 * 60)));
  }

  if ($ago > 60 * 2) {
    return sprintf('%d minutes ago', ($ago / (60)));
  }

  return sprintf('%d seconds ago', $ago);

}


# Display the a size in human-readable format
#
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


# Convert string to time
#
sub datetime_calc {

  my ($string) = @_;

  my ($sign, $digit, $order) = ($string =~ /^(\+|-|)(\d+)(h|d|m|y|days?|hours?|months?|years?)$/i);

  my $time = 0;

     $time = ONE_DAY   * $digit  if (lc($order) =~ /d/ || lc($order) =~ /day/);
     $time = ONE_HOUR  * $digit  if (lc($order) =~ /h/ || lc($order) =~ /hour/);
     $time = ONE_MONTH * $digit  if (lc($order) =~ /m/ || lc($order) =~ /month/);
     $time = ONE_YEAR  * $digit  if (lc($order) =~ /y/ || lc($order) =~ /year/);

  my $datetime = Time::Piece->new();

  if ($sign eq '' || $sign eq '+') {
    $datetime += $time;
  }
  if ($sign eq '-') {
    $datetime -= $time;
  }

  return $datetime;

}


# File read (aka slurp)
#
sub file_read {

  my ($filename) = @_;

  my $content = do {
    my $fh = file_handler($filename, '<');
    local $/ = undef;
    <$fh>
  };

  return $content;

}


# File write (overwrite mode)
#
sub file_write {

  my ($filename, $content) = @_;

  my $fh = file_handler($filename, '>');
  print $fh $content;
  close($fh);

  return;

}

# File write (append mode)
sub file_append {

  my ($filename, $content, $autoflush) = @_;

  my $fh = file_handler($filename, '>>');
     $fh->autoflush(1) if ($autoflush);

  print $fh $content;
  close($fh);

  return;

}


# Get file handler for file read/write/append
#
sub file_handler {

  my ($filename, $mode) = @_;
  my $fh;

  open($fh, $mode, $filename) or die "Could not open '$filename': $!";
  return $fh;

}


sub download_file {

  my ($url, $file, $progress) = @_;

  my $total_data;
  my $options = {};
  my $http    = http_client();

  logger->info("[DOWNLOAD] Downloading $url and save into $file");

  open(DOWNLOAD, '>', $file) or Carp::croak("Can't open file $file for downloading: $?");

  print "\r" if ($progress);

  $options->{data_callback} = sub {

    my ($data, $response) = @_;
    my $content_length = $response->{'headers'}->{'content-length'};

    print DOWNLOAD $data; # Save chunk into file

    $total_data .= $data;

    STDOUT->printflush( callback_progress_bar( basename($url), length($total_data), $content_length, 20, '=' ) ) if ($progress);

  };

  my $response = $http->request( 'GET', $url, $options );

  close (DOWNLOAD);

  if ( $response->{'success'} ) {
    logger->info("[DOWNLOAD] done");
    return $response->{status};
  }

  logger->error(sprintf("[DOWNLOAD] Download error: %s - %s", $response->{status}, $response->{reason}));
  return $response->{status};

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

  my $http = http_client();

  logger->debug("Get 'Last-Modified' date of $url");

  my $response = $http->request('HEAD', $url);

  if ( $response->{'success'} ) {
    my $last_modified = $response->{'headers'}{'last-modified'};
    return http_date_to_time($last_modified) if ($last_modified);
  }

  return 0;

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


sub http_date_to_time {

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


sub repo_option_to_sql {

  my ($table) = @_;

  my $field = 'repository';
     $field = "$table.$field" if ($table);

  my $option_repo = $slackman_opts->{'repo'};

  my @query_filters;

  my @enabled_repo  = Slackware::SlackMan::Repo::get_enabled_repositories();
  my @disabled_repo = Slackware::SlackMan::Repo::get_disabled_repositories();

  if ($option_repo) {

    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@query_filters, qq/$field LIKE "$option_repo"/);

  } else {
    push(@query_filters, sprintf(qq/$field IN ("%s")/, join('", "', @enabled_repo)));
  }

  push(@query_filters, sprintf(qq/$field NOT IN ("%s")/, join('","', @disabled_repo)));

  my $sql_filter = sprintf(' ( %s ) ', join(' AND ', @query_filters));

  return $sql_filter;

}


sub timestamp_options_to_sql {

  my $option_after  = $slackman_opts->{'after'};
  my $option_before = $slackman_opts->{'before'};

  my $parsed_after  = undef;
  my $parsed_before = undef;

  my @timestamp_filter = ();

  if ($option_after) {

    if ($option_after =~ /^(\+|-|)(\d+)(d|m|y|days?|months?|years?)$/) {
      $parsed_after = datetime_calc($option_after)->ymd;
    }

    if (! $parsed_after && $option_after =~ /^\d{4}-\d{2}-\d{2}/) {
      $parsed_after = $option_after;
    }

    push(@timestamp_filter, sprintf('(timestamp > "%s")', $parsed_after))  if ($parsed_after);

  }

  if ($option_before) {

    if ($option_before =~ /^(\+|-|)(\d+)(d|m|y|days?|months?|years?)$/) {
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

  my ($file) = @_;

  logger->debug(qq/[GPG] verify file "$file" with "$file.asc"/);

  system("gpg --verify $file.asc $file 2>/dev/null");
  return ($?) ? 0 : 1;

}


sub gpg_import_key {

  my ($key_file)   = @_;
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


my $slackware_release    = '';
my $is_slackware_current = 0;

sub _get_slackware_release {

  my $slackware_version_file = $slackman_conf->{'directory'}->{'root'} . '/etc/slackware-version';

  my ($slackware_version) = file_read($slackware_version_file) =~ (/Slackware (.*)/);

  if ($slackware_version =~ /\+/) {
    $slackware_version =~ s/\+//;
    $is_slackware_current = 1;
  }

  return $slackware_version;

}


sub is_slackware_current {
  return $is_slackware_current;
}


sub get_slackware_release {
  return $slackware_release ||= _get_slackware_release(); # Reduce "open" system call
}


sub get_package_info {

  my ($package_name) = @_;

  # Add default extension
  $package_name .= '.tgz' unless ($package_name =~ /\.(txz|tgz|tbz|tlz)/);

  $package_name = basename($package_name);

  my $package_basename;
  my $package_version;
  my $package_build;
  my $package_tag;
  my $package_arch;
  my $package_type;

  my @package_name_parts    = split(/-/, $package_name);
  my $package_build_tag_ext = $package_name_parts[$#package_name_parts];
     $package_build_tag_ext =~ /^(\d+)(.*)\.(txz|tgz|tbz|tlz)/;

  $package_build   = $1;
  $package_tag     = $2;
  $package_type    = $3;

  $package_arch    = $package_name_parts[$#package_name_parts-1];
  $package_version = $package_name_parts[$#package_name_parts-2];

  for (my $i=0; $i<$#package_name_parts-2; $i++) {
    $package_basename .= $package_name_parts[$i] . '-';
  }

  $package_tag      =~ s/^_// if ($package_tag);
  $package_basename =~ s/-$// if ($package_basename);

  return {
    'name'    => $package_basename,
    'package' => $package_name,
    'version' => $package_version,
    'build'   => $package_build,
    'tag'     => $package_tag,
    'arch'    => $package_arch,
    'type'    => $package_type,
  }

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


sub create_lock {

  my $pid = $$;
  my $lock_file = $slackman_conf->{'directory'}->{'lock'} . '/slackman';

  file_write($lock_file, $pid);

}


sub get_lock_pid {

  my $lock_file = $slackman_conf->{'directory'}->{'lock'} . '/slackman';

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

  my $lock_file = $slackman_conf->{'directory'}->{'lock'} . '/slackman';
  unlink($lock_file);

}


sub success_sign {
  return colored("\x{2713}", "green");
}


sub failed_sign {
  return colored("\x{2717}", "red");
}


sub str_pad {

  my ($input, $pad_length) = @_;

  Carp::croak("Usage: str_pad(input, pad_length)") unless ($pad_length);

  my $result = $input;
  my $length = length($input);

  for my $i (1..($pad_length-$length)) {
    $result .= ' ';
  }

  return $result;

}

sub terminal_width {

  my $res = qx{tput cols};
  chomp($res);
  return $res;

}


sub table {

  my ($args) = @_;

  my $col_separator    = $args->{'separator'}->{'column'} || ' ';
  my $header_separator = $args->{'separator'}->{'header'} || undef;
  my $rows             = $args->{'rows'}    || ();
  my $headers          = $args->{'headers'} || ();
  my $output_format    = $args->{'format'}  || 'default';
  my $widths           = ();

  my @checks = @$rows;

  push(@checks, $headers) if ($headers);

  if ($output_format eq 'default') {

    for my $row (@checks) {
      for (my $idx=0; $idx < @$row; $idx++) {

        if (defined($args->{'widths'}->[$idx]) && $args->{'widths'}->[$idx] > 0) {
          $widths->[$idx] = $args->{'widths'}->[$idx];
          next;
        }

        my $col = $row->[$idx];
        $widths->[$idx] = length($col) if (length($col) > ($widths->[$idx] || 0));

      }
    }

  } else {

    for (my $i=0; $i< @{$rows->[0]}; $i++) {
      $widths->[$i] = 1;
    }

    $header_separator = undef;

    $col_separator = ','  if ($output_format eq 'csv');
    $col_separator = "\t" if ($output_format eq 'tsv');

  }

  my $format = join($col_separator, map { "%-${_}s" } @$widths) . "\n";
  my $table  = '';

  if ($headers) {

    my $header_row   = sprintf($format, @$headers);
    my $header_width = length($header_row);

    if ($header_separator) {
      $table .= sprintf("%s\n", $header_separator x $header_width);
    }

    $table .= $header_row;

    if ($header_separator) {
      $table .= sprintf("%s\n", $header_separator x $header_width);
    }

  }

  for my $row (@$rows) {

    if ($output_format eq 'default') {
      $table .= sprintf($format, @$row);

    } else {
      $table .= sprintf($format, map { trim($_) } @$row);
    }

  }

  return $table;

}


1;
__END__

=head1 NAME

Slackware::SlackMan::Utils - SlackMan utility module

=head1 SYNOPSIS

  use Slackware::SlackMan::Utils qw(:all);

  my $content = file_read('/etc/slackware-version');

=head1 DESCRIPTION

utility module for SlackMan.

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

Copyright 2016-2018 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

