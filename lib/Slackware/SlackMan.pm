package Slackware::SlackMan;

use strict;
use warnings FATAL => 'all';

use 5.010;

use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Config  qw(:all);
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Repo    qw(:all);
use Slackware::SlackMan::Command qw(:all);

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  @ISA = qw(Exporter);

  $VERSION = 'v1.1.0-beta1';

  @EXPORT_OK = (
    @Slackware::SlackMan::Utils::EXPORT_OK,
    @Slackware::SlackMan::Package::EXPORT_OK,
    @Slackware::SlackMan::Config::EXPORT_OK,
    @Slackware::SlackMan::DB::EXPORT_OK,
    @Slackware::SlackMan::Parser::EXPORT_OK,
    @Slackware::SlackMan::Repo::EXPORT_OK,
    @Slackware::SlackMan::Command::EXPORT_OK,
    @Slackware::SlackMan::Logger::EXPORT_OK,
  );

  %EXPORT_TAGS = (
    'all'     => \@EXPORT_OK,
    'utils'   => \@Slackware::SlackMan::Utils::EXPORT_OK,
    'package' => \@Slackware::SlackMan::Package::EXPORT_OK,
    'config'  => \@Slackware::SlackMan::Config::EXPORT_OK,
    'db'      => \@Slackware::SlackMan::DB::EXPORT_OK,
    'parser'  => \@Slackware::SlackMan::Parser::EXPORT_OK,
    'repo'    => \@Slackware::SlackMan::Repo::EXPORT_OK,
    'command' => \@Slackware::SlackMan::Command::EXPORT_OK,
    'logger'  => \@Slackware::SlackMan::Logger::EXPORT_OK,
  );

}

1;
__END__

=head1 NAME

Slackware::SlackMan - SlackMan Core module

=head1 SYNOPSIS

  use Slackware::SlackMan qw(:package);

  my $pkg_info = package_info('aaa_base-14.2-x86_64-1.tgz');

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
