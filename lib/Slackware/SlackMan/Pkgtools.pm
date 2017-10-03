package Slackware::SlackMan::Pkgtools;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.2.0';
  @ISA     = qw(Exporter);

  @EXPORT = qw{
    installpkg
    removepkg
    upgradepkg
    reinstallpkg
  };

  @EXPORT_OK = qw(
  );

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Package qw(:all);

use Carp ();
use File::Basename;
use Data::Dumper;

sub installpkg {
  _pkgtool_action('install', @_);
}

sub upgradepkg {
  _pkgtool_action('upgrade', @_);
}

sub removepkg {
  _pkgtool_action('remove', @_);
}

sub reinstallpkg {

  my @args = @_;
  push(@args, 'reinstall');

  _pkgtool_action('upgrade', @args);

}

sub _to_params {
  return map { ((length($_) > 1) ? "--$_" : "-$_") } @_;
}

sub _pkg_exists {

  my ($package) = @_;

  if ( $package =~ /%/ ) {
    my ($old, $new) = split(/%/, $package);
    $package = $new;
  }

  Carp::croak(sprintf('Package %s not found!', $package)) unless (-f $package);

}

sub _pkgtool_action {

  my $action   = shift;
  my $package  = shift;
  my @params   = _to_params(@_);

  _pkg_exists($package) unless ($action eq 'remove');

  unless ($action eq 'remove') {

    my $pkg_info = get_package_info(basename($package));

    logger->debug(sprintf('[pkgtool:%s] %s package (version: %s, arch: %s, build: %s, tag: %s)',
      $action, $pkg_info->{'name'},  $pkg_info->{'version'}, $pkg_info->{'arch'},
              $pkg_info->{'build'}, $pkg_info->{'tag'}));

  } else {
    logger->debug(sprintf('[pkgtool:%s] %s package', $action, $package));
  }

  my $cmd = join(' ', sprintf('/sbin/%spkg', $action), @params, $package);

  logger->debug(sprintf('[pkgtool:%s] %s', $action, $cmd));

  system($cmd);

  logger->debug(sprintf('[pkgtool:%s] done', $action));

}

1;
__END__

=head1 NAME

Slackware::SlackMan::Pkgtools - SlackMan Pkgtools module wrapper

=head1 SYNOPSIS

  use Slackware::SlackMan::Pkgtools;

  # Install
  installpkg( '/tmp/foo-1.2-x86_64-1_lotar' );

  # Upgrade
  upgradepkg( '/tmp/foo-1.2-x86_64-1_lotar' );

  # Reinstall
  upgradepkg( '/tmp/foo-1.2-x86_64-1_lotar', 'reinstall' )

  # or (alias)
  reinstallpkg( '/tmp/foo-1.2-x86_64-1_lotar' )

=head1 DESCRIPTION

Pkgtools module wrapper for SlackMan.

=head1 EXPORT

=head1 SUBROUTINES

=head1 VARIABLES

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Pkgtools

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

