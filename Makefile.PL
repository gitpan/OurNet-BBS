#!/usr/bin/perl

require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Component Object Model for BBS systems',
    NAME            => 'OurNet::BBS',
    VERSION_FROM    => 'BBS.pm',
    DISTNAME        => 'OurNet-BBS',
    BINARY_LOCATION => 'x86/OurNet-BBS.tar.gz',

    PREREQ_PM       => {
	'Bundle::PlRPC'		=> '0.03',	# Server, Client
        'Date::Parse'		=> '2.20',	# DBI, MAPLE2, MELIX, NNTP
	'Digest::MD5'		=> '2.10',	# Server, Client, Utils
	'File::Temp'		=> '0.12',	# Test scripts
        'Mail::Address'		=> '1.17',	# BBSAgent, MAPLE2, MELIX
	'Net::NNTP'		=> '2.19',	# NNTP
	'Mail::Box'		=> '1.313',     # MailBox
	'OurNet::BBSAgent'	=> '1.53',	# BBSAgent
        'Term::ReadKey'         => '2.13',	# bbscomd
	'enum'			=> '1.016',	# MAPLE3
    },

    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);
