#!/usr/bin/perl
# $File: //depot/OurNet-BBS/Makefile.PL $ $Author: autrijus $
# $Revision: #30 $ $Change: 2441 $ $DateTime: 2001/11/27 15:42:06 $

use 5.006;
use strict;
use warnings;

# ExtUtils::AutoInstall Bootstrap Code, version 1.
BEGIN { my $p='ExtUtils::AutoInstall'; eval"use $p 0.21;1" or(print
	"*** Fetching $p.\n"), require CPAN, CPAN::install $p; eval
	"use $p 0.21;1" or die "*** Please install $p manually.\n"}

my @ciphers = map { "Crypt::$_" } (
    qw/Rijndael Twofish2 Twofish Blowfish IDEA DES/,
    qw/TEA GOST Rijndael_PP Blowfish_PP DES_PP/,
);

my ($have_ciph, @cipher_module);
foreach my $cipher (@ciphers) {
    ++$have_ciph and last if eval "use $cipher (); 1";
}

require Config;

unless (!$have_ciph) {
    @cipher_module = have($Config::Config{cc})
        ? ('Crypt::Rijndael' => '0.03') : ('Crypt::Rijndael_PP' => '0.01');
}

use ExtUtils::AutoInstall;

ExtUtils::AutoInstall->import(
    -version			=> '0.21',
    -core 			=> [
        'Date::Parse'		=> '2.20',	# RAM, MAPLE2, MELIX, NNTP
	'Digest::MD5'		=> '2.10',	# Server, Client, Utils
	'File::Temp'		=> '0.12',	# Test scripts
	'Mail::Address'		=> '1.17',	# BBSAgent, MAPLE2, MELIX
        'Test::Harness'		=> '1.23',
        'File::Spec'		=> '0.6',
        'Test::More'		=> '0.31',	# tests
	'enum'			=> '1.016',	# MAPLE3
    ],
    'OurNet Server (bbscomd)'	=> [
	-tests   		=> [ <t/*-OurNet-*.t>],
	'Storable'		=> '1.011',
	'Net::Daemon'		=> '0.13',
	'RPC::PlServer'		=> '0.2013',
	@cipher_module,
    ],
    'OurNet Client'		=> [
	'Storable'		=> '1.011',
	'RPC::PlClient'		=> '0.2013',
	@cipher_module,
    ],
    'GnuPG Encryption'		=> [ 
	-default		=> (have('gpg') and have($Config::Config{cc})),
     	'Class::MethodMaker'	=> '1.00',
	'GnuPG::Interface'	=> '0.31',
	'Term::ReadKey'		=> '2.13',
    ],
    'Usenet News (NNTP)'	=> [
	'Net::NNTP'		=> '2.19',
    ],
    'Mailbox File (MailBox)'	=> [
	-default 		=> ($^O ne 'MSWin32'),
	-tests   		=> [ 't/6-MailBox.t'],
    	'Mail::Internet'	=> '1.0',
	'MIME::Tools'		=> '5.0',
	'IO::Scalar'		=> '1.0',
	'Mail::Box'		=> '1.313',
    ],
    'Telnet BBS (BBSAgent)'	=> [
	-tests   		=> [ 't/5-BBSAgent.t'],
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
    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);

sub have {
    # do we have something?
    return grep {
        -x "$_/$_[0]" or -x "$_/$_[0].exe"
    } split($Config::Config{path_sep}, $ENV{PATH});
}
