# $File: //depot/OurNet-BBS/BBS/PTT/Session.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::PTT::Session;

use base qw/OurNet::BBS::MAPLE2::Session/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() }

1;
