# $File: //depot/OurNet-BBS/BBS/OurNet/BBS.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::OurNet::BBS;

use strict;
use OurNet::BBS::Client;

sub new { 
    return OurNet::BBS::Client->new(@_[2..$#_]);
}

1;
