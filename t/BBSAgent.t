#!/usr/bin/perl -w
use strict;
use Test;
use vars qw/%sites/;

# use a BEGIN block so we print our plan before MyModule is loaded

BEGIN {
    my $addr;

    %sites = map { 
        open _; scalar <_>;
        chomp($addr = <_>);
        (substr($_, rindex($_, '/') + 1) => (split(':', $addr))[0]);
    } map {
        glob("$_/OurNet/BBSAgent/*.bbs")
    } @INC;

    plan tests => scalar keys(%sites) * 2;
}

# Load BBS
use OurNet::BBS;
use Socket 'inet_aton';

$OurNet::BBS::DEBUG = $OurNet::BBS::DEBUG++; # shut up warnings

print "# note: when called with an argument, this script will\n";
print "#       also test login sanity for each .bbs.\n";

while (my ($site, $addr) = each %sites) {
    ok(my $BBS = OurNet::BBS->new('BBSAgent', $site));

    if (defined inet_aton($addr)) {
        my $result = eval {
	    $BBS->sanity_test(!$ARGV[0])
	};

	if ($@ =~ /problem connecting/) {
	    skip($@, 1);
	}
	else {
	    warn $@ if $@;
	    ok($result);
	}
    }
    else {
        skip("not connected to $addr", 1);
    }
}

__END__
