package Slackware::SlackMan::Command::Config;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.2.0';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Utils  qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;
use Pod::Find qw(pod_where);

use constant COMMANDS_DISPATCHER => {

  'help.config'  => \&call_config_help,
  'config.help'  => \&call_config_help,

  'config'       => \&call_config,

};

use constant COMMANDS_MAN => {
  'config' => \&call_config_man
};

use constant COMMANDS_HELP => {
  'config' => \&call_config_help
};

my $log_file = $slackman_conf{'logger'}->{'file'};

sub call_config_man {

 pod2usage(
    -input   => pod_where({-inc => 1}, __PACKAGE__),
    -exitval => 0,
    -verbose => 2
  );

}

sub call_config_help {

  pod2usage(
    -input    => pod_where({-inc => 1}, __PACKAGE__),
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}

sub call_config {

  my ($config_key, $config_value) = @_;

  # Set SlackMan config value
  if ($config_key && $config_value) {

    my $slackman_conf_file = $slackman_conf{'config'}->{'file'};

    my ($section, $parameter) = split(/\./, $config_key);
    file_write($slackman_conf_file, set_config(file_read($slackman_conf_file), "[$section]", $parameter, $config_value));

    exit(0);

  }

  # Get or display all SlackMan config values

  foreach my $section (sort keys %slackman_conf) {
    foreach my $parameter (sort keys %{$slackman_conf{$section}}) {

      my $param_value = $slackman_conf{$section}->{$parameter};
      my $param_name  = "$section.$parameter";

      if ($config_key) {

        if ($config_key eq $param_name) {
          print "$param_value\n";
        }

      } else {
        print sprintf("%s=%s\n", $param_name, $param_value);
      }

    }
  }

  exit(0);

}

1;
__END__
=head1 NAME

slackman-config - Get and set SlackMan configuration

=head1 SYNOPSIS

  slackman config
  slackman config OPTION
  slackman config OPTION VALUE
  slackman config help

=head1 DESCRIPTION

B<slackman config> get and set SlackMan configuration in L<slackman.conf(5)> file.

=head1 OPTIONS

  -c, --config=FILE          Configuration file
  -h, --help                 Display help and exit
  --man                      Display man pages
  --version                  Display version information

=head1 SEE ALSO

L<slackman(8)>, L<slackman.conf(5)>

=head1 BUGS

Please report any bugs or feature requests to 
L<https://github.com/LotarProject/slackman/issues> page.

=head1 AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2017 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
