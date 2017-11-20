package Slackware::SlackMan;

use strict;
use warnings FATAL => 'all';

use 5.010;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  @ISA = qw(Exporter);

  $VERSION   = 'v1.2.1';
  @EXPORT_OK = ();
  @EXPORT    = qw(
    $slackman_opts
    %slackman_conf
    logger
  );

  %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
  );

}

use Carp 'confess';

use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Logger;

# FIX "Can't locate Term/ReadLine/Perl.pm [...]" message
$ENV{PERL_RL} = 'Stub';

our %slackman_conf = load_config();
our $slackman_opts = {};

# Set default options
$slackman_opts->{'limit'} ||= 25;

my $logger_conf = $slackman_conf{'logger'};

my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext,
    $is_require, $hints, $bitmask, $hinthash) = caller(0);

our $logger = Slackware::SlackMan::Logger->new( 'file'     => $logger_conf->{'file'},
                                                'level'    => $logger_conf->{'level'},
                                                'category' => $subroutine );

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
