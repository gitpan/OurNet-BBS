#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Component Object Model for BBS systems',
    NAME            => 'LWP::Protocol::bbs',
    VERSION_FROM    => 'bbs.pm',

    PREREQ_PM       => {
        'LWP'         => '5.00',
    },
);

