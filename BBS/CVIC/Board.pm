# $File: //depot/OurNet-BBS/BBS/CVIC/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::CVIC::Board;

use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_cache/;

BEGIN {__PACKAGE__->initvars()};

1;
