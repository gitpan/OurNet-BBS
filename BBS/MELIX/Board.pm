# $File: //depot/OurNet-BBS/BBS/MELIX/Board.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::Board;

use strict;
use base qw/OurNet::BBS::MAPLE3::Board/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() };

1;
