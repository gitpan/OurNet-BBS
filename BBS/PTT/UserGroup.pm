# $File: //depot/OurNet-BBS/BBS/PTT/UserGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::PTT::UserGroup;

use base qw/OurNet::BBS::MAPLE2::UserGroup/;
use fields qw/_cache _phash/;

BEGIN { __PACKAGE__->initvars() }

1;
