#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Component Object Model for BBS systems',
    NAME            => 'OurNet::BBS',
    VERSION_FROM    => 'BBS.pm',
    DISTNAME        => 'OurNet-BBS',
    BINARY_LOCATION => 'x86/OurNet-BBS.tar.gz',

    PREREQ_PM       => {
	'RPC::PlClient'		=> '0.2012',     # BBSCOM
        'Mail::Address'		=> '1.17',       # BBSCOM
        'Date::Parse'		=> '2.20',       # BBSCOM
	'Digest::MD5'		=> '2.10',       # BBSCOM
	'Net::NNTP'		=> '2.19',       # NNTP backend
        'Term::ReadKey'         => '2.13',       # bbscom
	'LWP'			=> '5.00',       # LWP-BBS
	'OurNet::BBSAgent'	=> '1.53',       # BBSAgent backend
	'File::Temp'		=> '0.12',       # test scripts
	'enum'			=> '1.016',      # OurNet::BBS::MAPLE3::USER
    },

    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);

# Fix a bug for Win95 nmake
if ($^O =~ /Win32/ and -e 'Makefile') {
    local $/;
    open _, 'Makefile';
    my $content = <_>;
    $content =~ s/\n\@\[\n/\n/g;
    $content =~ s/\n\]\n/\n\n/g;
    close _;
    open _, '>Makefile' or exit;
    print _ $content;
}


