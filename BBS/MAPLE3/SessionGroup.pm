# $File: //depot/OurNet-BBS/BBS/MAPLE3/SessionGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::MAPLE3::SessionGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN {
    __PACKAGE__->initvars(
	'$packstring'	=> 'LLLSSLLLa36Z13Z13Z24Z34',
	'$packsize'	=> 152,
	'@packlist'	=> [ qw(
	    pid uid idle_time mode ufo sockaddr sockport destuip msgs 
	    userid mateid username from
	) ],
    );
}

1;
