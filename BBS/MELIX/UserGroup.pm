# $File: //depot/OurNet-BBS/BBS/MELIX/UserGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::UserGroup;

use base qw/OurNet::BBS::MAPLE3::UserGroup/;
use fields qw/_cache _phash/;

BEGIN { __PACKAGE__->initvars() }

1;
