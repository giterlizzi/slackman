use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Slackware::Slackman',
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
        'Test::Trap' => '0',
    },
    PREREQ_PM => {
        'DBD::SQLite'       => '0',
        'Sort::Versions'    => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Slackware-Slackman-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
man: pod/Makefile
	cd pod && $(MAKE) install
MAKE_FRAG
}