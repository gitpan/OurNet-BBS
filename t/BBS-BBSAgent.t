use strict;
use Test;
use vars qw/%sites/;

# use a BEGIN block so we print our plan before MyModule is loaded

BEGIN {
	%sites = map { 
		open _; 
		scalar <_>;
		(substr($_, rindex($_, '/') + 1), (split(':', scalar <_>))[0]);
	} map {
		glob("$_/OurNet/BBSAgent/*.bbs")
	} @INC;

	plan tests => scalar keys(%sites) * 2;
}

# Load BBS
use OurNet::BBS;
use Socket 'inet_aton';

$OurNet::BBS::DEBUG++;
$OurNet::BBS::DEBUG++; # shut up

my $count;
print "# note: when called with argument, this script will\n";
print "#       also test login sanity for each .bbs.\n";

while (my ($site, $addr) = each %sites) {
	ok(my $BBS = OurNet::BBS->new('BBSAgent', $site));
	my $brd = $BBS->{boards};

	if (inet_aton($sites{$site})) {
		ok($BBS->{boards}->sanity_test(!$ARGV[0]));
	}
	else {
		skip("not connected to $addr", 1);
	}
}

__END__
