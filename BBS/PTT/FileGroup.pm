# $File: //depot/OurNet-BBS/BBS/PTT/FileGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1266 $ $DateTime: 2001/06/23 16:54:04 $

package OurNet::BBS::PTT::FileGroup;

use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() }

1;
