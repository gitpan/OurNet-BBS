# $File: //depot/OurNet-BBS/BBS/OurNet/BBS.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 2999 $ $DateTime: 2002/02/04 15:00:28 $

package OurNet::BBS::OurNet::BBS;

use strict;
use OurNet::BBS::Client;

sub new { 
    if (ref($_[1])) {
	# hashref
	return OurNet::BBS::Client->new(@{$_[1]}{qw{
	    bbsroot peerport keyid user password cipher_level auth_level
	}});
    }
    else {
	# plain
	return OurNet::BBS::Client->new(@_[2..$#_]);
    }
}

1;
