#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/5-BBSAgent.t $ $Author: autrijus $
# $Revision: #5 $ $Change: 2069 $ $DateTime: 2001/10/15 08:02:05 $

use strict;
my ($addr, %sites);

BEGIN {
    unless (eval "use OurNet::BBSAgent; 1;") {
	eval "use Test::More tests => 1;";
	SKIP: { skip('OurNet::BBSAgent not installed', 1) };
	exit;
    }

    %sites = map { 
        open(my $SITE, $_) or die "cannot open $_";
	scalar <$SITE>;
        chomp($addr = <$SITE>);
        (substr($_, rindex($_, '/') + 1) => (split(':', $addr))[0]);
    } map {
        glob("$_/OurNet/BBSAgent/*.bbs")
    } reverse @INC;
}

use Test::More tests => keys(%sites) * 2;

# Load BBS
use OurNet::BBS;
use Socket 'inet_aton';

$OurNet::BBS::DEBUG = $OurNet::BBS::DEBUG++; # shut up warnings

print << "." unless @ARGV;
# note: when called with an argument, this script will
#       also test login + sanity for each .bbs files.
.

while (my ($site, $addr) = each %sites) {
    my $BBS = OurNet::BBS->new(BBSAgent => $site);
    is(ref($BBS), $BBS->module('BBS'), "load: $site");

    SKIP: {
	skip "no \@ARGV, skips sanity test", 1
	    unless ($ARGV[0]);

	skip "not connected to $addr", 1
	    unless (defined inet_aton($addr));

        my $result = eval {
	    $BBS->sanity_test(!$ARGV[0])
	};

	ok($result, "connect: $site");
    }
}

__END__
