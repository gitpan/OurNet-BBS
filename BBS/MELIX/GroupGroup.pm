# $File: //depot/OurNet-BBS/BBS/MELIX/GroupGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1270 $ $DateTime: 2001/06/24 07:15:18 $

package OurNet::BBS::MELIX::GroupGroup;

use base qw/OurNet::BBS::MAPLE3::GroupGroup/;
use fields qw/_cache _phash/;

BEGIN { __PACKAGE__->initvars() };

1;
