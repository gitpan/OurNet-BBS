# $File: //depot/OurNet-BBS/BBS/CVIC/SessionGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::CVIC::SessionGroup;

use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;

use OurNet::BBS::Base (
    '$packstring' => 
        'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL',
    '$packsize'   => 1488,
);

1;
