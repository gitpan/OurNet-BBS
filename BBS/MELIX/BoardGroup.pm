# $File: //depot/OurNet-BBS/BBS/MELIX/BoardGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::BoardGroup;

use strict;
use base qw/OurNet::BBS::MAPLE3::BoardGroup/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() };

1;
