package Slackware::SlackMan::DBus;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta4';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw{};

}

use Data::Dumper;
use JSON::PP;

use Slackware::SlackMan::Package qw(:all);

use Net::DBus::Exporter 'org.lotarproject.slackman';
use base qw(Net::DBus::Object);

sub new {

  my $class   = shift;
  my $service = shift;

  my $self = $class->SUPER::new($service, '/org/lotarproject/slackman');

  bless $self, $class;

  return $self;

}

dbus_method('Hello', ['string'], ['string']);
sub Hello {
  my $self = shift;
  my ($name) = @_;
  return "Hello $name";
}

dbus_method('ChangeLogs', [], ['string']);

sub ChangeLogs {

  my $self = shift;
  my ($name) = @_;

  my $changelogs = package_changelogs();

  return encode_json($changelogs);

}

1;
__END__

=head1 NAME

Slackware::SlackMan::DBus - SlackMan DBus module

=head1 SYNOPSIS

  use Slackware::SlackMan::DBus;

=head1 DESCRIPTION

D-Bus interface module for SlackMan.

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

  perldoc Slackware::SlackMan::Repo

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

