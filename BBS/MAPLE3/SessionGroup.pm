# $File: //depot/OurNet-BBS/BBS/MAPLE3/SessionGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MAPLE3::SessionGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$packstring'	=> 'LLLSSLLLa36Z13Z13Z24Z34',
    '$packsize'		=> 152,
    '@packlist'		=> [ qw(
        pid uid idle_time mode ufo sockaddr sockport destuip msgs 
        userid mateid username from
    ) ],
);

1;
