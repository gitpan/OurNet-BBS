# $File: //depot/OurNet-BBS/BBS/MELIX/GroupGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::GroupGroup;

use base qw/OurNet::BBS::MAPLE3::GroupGroup/;
use fields qw/_cache _phash/;

BEGIN { __PACKAGE__->initvars() };

1;
