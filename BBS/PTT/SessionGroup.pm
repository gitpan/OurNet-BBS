# $File: //depot/OurNet-BBS/BBS/PTT/SessionGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::PTT::SessionGroup;

use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    die "Session support at PTT now broken"; 
    # XXX ... and we're not going to fix it.
}

1;
