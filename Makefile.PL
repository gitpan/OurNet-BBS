#!/usr/bin/perl
# $File: //depot/OurNet-BBS/Makefile.PL $ $Author: autrijus $
# $Revision: #14 $ $Change: 2061 $ $DateTime: 2001/10/15 06:43:00 $

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::AutoInstall (
    '' => [
        'Date::Parse'		=> '2.20',	# RAM, MAPLE2, MELIX, NNTP
	'Digest::MD5'		=> '2.10',	# Server, Client, Utils
	'File::Temp'		=> '0.12',	# Test scripts
        'Mail::Address'		=> '1.17',	# BBSAgent, MAPLE2, MELIX
        'Test::More'		=> '0.11',	# tests
	'enum'			=> '1.016',	# MAPLE3
    ],
    'OurNet Connectivity (bbscomd)'	=> [
	'Bundle::PlRPC'		=> '0.03',
    ],
    'GnuPG Encryption'			=> [
	sub { local $@; eval { `gpg --version` }; !$@ },
	'GnuPG::Interface'	=> '0.31',
	'Term::ReadKey'		=> '2.13',
    ],
    'Usenet News (NNTP)'		=> [
	'Net::NNTP'		=> '2.19',
    ],
    'Mailbox File (MailBox)'		=> [
	sub { $^O ne 'MSWin32' },
	'Mail::Box'		=> '1.313',
    ],
    'Telnet BBS (BBSAgent)'		=> [
	'OurNet::BBSAgent'	=> '1.55',
    ],
);

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Component Object Model for BBS systems',
    NAME            => 'OurNet::BBS',
    VERSION_FROM    => 'BBS.pm',
    DISTNAME        => 'OurNet-BBS',
    BINARY_LOCATION => 'x86/OurNet-BBS.tar.gz',

    PREREQ_PM       => PREREQ_PM,
    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);
