# $File: //depot/OurNet-BBS/BBS/CVIC/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::CVIC::BoardGroup;

use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_cache _shm _shmid/;

BEGIN {__PACKAGE__->initvars()};

1;
