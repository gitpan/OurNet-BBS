# $File: //depot/OurNet-BBS/BBS/PTT/SessionGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::PTT::SessionGroup;

use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() };

sub refresh_meta {
    die "Session support at PTT now broken"; 
    # XXX ... and we're not going to fix it.
}

1;
