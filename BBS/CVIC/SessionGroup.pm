# $File: //depot/OurNet-BBS/BBS/CVIC/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::CVIC::SessionGroup;

use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 
	    'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL',
        '$packsize'   => 1488,
    );
}

1;
