# $File: //depot/OurNet-BBS/BBS/CVIC/SessionGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::SessionGroup;

use strict;
use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$packstring' => 
        'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL',
    '$packsize'   => 1488,
);

sub writeok { 0 };
sub readok { 1 };

1;
