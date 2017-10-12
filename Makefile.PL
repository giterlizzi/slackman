use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Slackware::SlackMan',
    AUTHOR           => q{Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>},
    VERSION_FROM     => 'lib/Slackware/SlackMan.pm',
    ABSTRACT_FROM    => 'lib/Slackware/SlackMan.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [ 'bin/slackman' ],
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'DBD::SQLite'     => '0',
        'Net::DBus'       => '0',
        'HTTP::Tiny'      => '0', # Core since Perl v5.13.9/5.14.0 or from Slackware 14.0 (Perl v5.16)
        'IO::Socket::SSL' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Slackware-Slackman-*' },
);

sub add_dep {
    my ($string, $targ, $add) = @_;
    $$string =~ s/($targ\s+::)/$1 $add/;
}

sub MY::top_targets {

    my $self = shift;
    my $string = $self->MM::top_targets;

    $string .= <<"EOF";
dbus_install:
	cd dbus && \$(MAKE) DESTDIR=\$(DESTDIR) install

man_install:
	cd pod && \$(MAKE) DESTDIR=\$(DESTDIR) install

etc_install:
	cd etc && \$(MAKE) DESTDIR=\$(DESTDIR) install
EOF

    $string;

}

sub MY::install {

    my $self = shift;
    my $string = $self->MM::install(@_);

    add_dep(\$string, pure_install => 'dbus_install');
    add_dep(\$string, pure_install => 'man_install');
    add_dep(\$string, pure_install => 'etc_install');

    $string;

}

sub MY::postamble {
    return <<'MAKE_FRAG';

SLACKBUILD_VERSION = $(shell echo $(VERSION) | tr -d "v" )

slackbuild: dist
	$(CP) $(DISTVNAME).tar.gz slackbuilds/slackman
	( cd slackbuilds/slackman && VERSION=$(SLACKBUILD_VERSION) $(SHELL) -x slackman.SlackBuild )

MAKE_FRAG
}
