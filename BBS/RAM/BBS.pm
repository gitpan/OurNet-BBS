# $File: //depot/OurNet-BBS/BBS/RAM/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1662 $ $DateTime: 2001/09/02 05:54:09 $

package OurNet::BBS::RAM::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
);

1;
