# $File: //depot/OurNet-BBS/BBS/Cola/BBS.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1825 $ $DateTime: 2001/09/16 21:27:34 $

package OurNet::BBS::Cola::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
);

1;
