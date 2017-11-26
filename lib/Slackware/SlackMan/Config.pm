package Slackware::SlackMan::Config;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.2.1';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw( get_config );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

sub new {

  my $class = shift;

  my $self  = {
    'file'    => shift,
    'content' => '',
    'data'    => {},
  };

  bless $self, $class;

  $self->_init();
  return $self;

}


sub _init {

  my ($self) = @_;

  if ( -e $self->{'file'} ) {

    my $config_string = _slurp($self->{'file'});

    $self->{'data'}    = $self->parse($config_string);
    $self->{'content'} = $config_string;

  }

}


sub _slurp {

  my ($file) = @_;

  open(CONFIG, '<', $file) or die("Can't open config file: $?");

  my $config_string = do {
    local $/ = undef;
    <CONFIG>
  };

  close(CONFIG);

  return $config_string;

}


sub _write {

  my ($file, $content) = @_;

  open(CONFIG, '>', $file) or die("Can't open config file: $?");
  print CONFIG $content;
  close(CONFIG);

}


sub _trim {

  my ($string) = @_;
  return $string unless($string);

  $string =~ s/^\s+|\s+$//g;
  return $string;

}


sub _parse_line {

  my ($value) = @_;

  return 1 if ($value =~ /^(yes|true)$/);
  return 0 if ($value =~ /^(no|false)$/);

  if ($value =~ /\,/) {
    return map { _trim($_) } split(/,/, $value) if ($value =~ /\,/);
  }

  return $value;

}


sub get {

  my ($self, $key) = @_;

  my $value = undef;

  if ($key =~ /\./) {

    my ($section, $subkey) = split(/\./, $key);

    if (    defined($self->{'data'}->{$section})
         && defined($self->{'data'}->{$section}->{$subkey}) ) {
      $value = $self->{'data'}->{$section}->{$subkey};
    }

  } else {
    $value = $self->{'data'}->{$key} if ( defined($self->{'data'}->{$key}) );
  }

  return $value;

}


sub set {

  my ($self, $key, $value) = @_;

  if ($key =~ /\./) {

    my ($section, $subkey) = split(/\./, $key);

    if (    defined($self->{'data'}->{$section})
         && defined($self->{'data'}->{$section}->{$subkey}) ) {
      $self->{'data'}->{$section}->{$subkey} = $value;
      return $value;
    }

  } else {
    if ( defined($self->{'data'}->{$key}) ) {
      $self->{'data'}->{$key} = $value;
      return $value;
    }
  }

}


sub delete {

  my ($self, $key) = @_;

  if ($key =~ /\./) {

    my ($section, $subkey) = split(/\./, $key);

    if (    defined($self->{'data'}->{$section})
         && defined($self->{'data'}->{$section}->{$subkey}) ) {
      delete( $self->{'data'}->{$section}->{$subkey} );
    }

  } else {
    if ( defined($self->{'data'}->{$key}) ) {
      delete($self->{'data'}->{$key});
    }
  }


}


sub param {

  my ($self, $key, $value) = @_;

  return $self->get($key) if ($key && ! $value);
  return $self->set($key, $value);

}


sub data {

  my ($self) = @_;
  return $self->{'data'};

}


sub parse {

  my ($self, $config_string) = @_;

  my @lines = split(/\n/, $config_string);

  my $section;
  my %config_data = ();

  foreach my $line (@lines) {

    chomp($line);

    # skip comments and empty lines
    next if ($line =~ /^\s*(#|;)/);
    next if ($line =~ /^\s*$/);

    if ($line =~ /^\[(.*)\]\s*$/) {
      $section = _trim($1);
      next;
    }

    if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/) {

      my ($field, $raw_value) = ($1, $2);
      my $parsed_value = [ _parse_line($raw_value) ];

      my $value = (( @$parsed_value == 1 ) ? $parsed_value->[0] : $parsed_value);

      if (not defined $section) {
        $config_data{$field} = $value;
        next;
      }

      $config_data{$section}{$field} = $value;

    }

  }

  $self->{'data'} = \%config_data;

  return \%config_data;

}


sub stringify {

  my ($self) = @_;

  my $ini_string = '';

  foreach my $section ( keys %{ $self->{'data'} } ) {

    $ini_string .= sprintf("\n[%s]\n", $section);

    foreach my $key (keys %{ $self->{'data'}->{$section} }) {
      $ini_string .= sprintf( "%s = %s\n", $key, $self->{'data'}->{$section}->{$key} );
    }

  }

  $ini_string =~ s/^\n//;

  return $ini_string;

}


sub save {

  my ($self, $file) = @_;

  $file = $self->{'file'} unless ($file);

  my $content = $self->stringify();

  _write($file, $content);

}


sub replace {

  my ($self, $param, $new_value) = @_;

  my $config_string   = _slurp($self->{'file'});
  my $current_section = '';
  my @lines   = split(/\n/, $config_string);
  my $output  = '';
  my $section = '';

  if ($param =~ /\./) {
    ($section, $param) = split(/\./, $param);
  }

  foreach my $line ( @lines ) {

    if ( $line =~ /^\[(.*)\]\s*$/ ) {
      $current_section = _trim($1);

    } elsif ( $current_section eq $section )  {

      my ( $key, $value ) = ( $line =~ m/^\s*([^=]*[^\s=])\s*=\s*(.*?\S)\s*$/ );

      if ( $key && $key eq $param ) {
        $output .= "$param = $new_value\n";
        next;
      }

    }

    $output .= "$line\n";

  }

  return $output;

}


sub replaceAndSave {

  my ($self, $param, $new_value, $file) = @_;

  my $output = $self->replace($param, $new_value);

  $file = $self->{'file'} unless($file);

  _write($file, $output);

}


sub get_config {

  my ($file) = @_;

  my $cfg = Slackware::SlackMan::Config->new($file);
  return $cfg->{'data'};

}

1;
__END__

=head1 NAME

Slackware::SlackMan::Config - SlackMan Config module

=head1 SYNOPSIS

  use Slackware::SlackMan::Config;

  my $cfg = Slackware::SlackMan::Config->new('/etc/slackman/slackman.conf');

  # get value
  $cfg->param('slackware.version');

  $cfg->get('slackware.version');

  # set value
  $cfg->param('slackware.version', 'current');

  $cfg->set('slackware.version', 'current');

  # Stringify config
  my $config_string = $cfg->stringify();

  # Save a config (create a clean config file -- loose the comments)
  $cfg->save();

  # Save a backup
  $cfg->save('/tmp/slackman.conf.bak');

  # Replace config value and return a string
  my $config_string = $cfg->replace('slackware.version', 'current');

  # Replace config value and save (preserve the comments)
  $cfg->replaceAndSave('slackware.version', 'current');

  # Return config hash
  my $config = $cfg->data();

  # Parse a config string and return the hash
  my $config = $cfg->parse(<<CFG
  [main]
  # This is a comment
  foo = bar
  CFG
  );

=head1 DESCRIPTION

Config module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 get_config ( $config_file )

=head1 METHODS

=head2 Slackware::SlackMan::Config->new ( [ $config_file ] )

=head2 Slackware::SlackMan::Config->parse ( $config_string )

=head2 Slackware::SlackMan::Config->param ( $param_name [, $param_value ] )

=head2 Slackware::SlackMan::Config->get ( $param_name )

=head2 Slackware::SlackMan::Config->set ( $param_name , $param_value )

=head2 Slackware::SlackMan::Config->save ( [ $file ] )

=head2 Slackware::SlackMan::Config->replace ( )

=head2 Slackware::SlackMan::Config->replaceAndSave ( [ $file ] )

=head2 Slackware::SlackMan::Config->stringify ( )

=head2 Slackware::SlackMan::Config->data ( )

=head1 VARIABLES

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
