# $File: //depot/OurNet-BBS/BBS/RAM/BBS.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1942 $ $DateTime: 2001/10/01 03:58:48 $

package OurNet::BBS::RAM::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
    '@USERS'    => [qw/bbsroot/],
    '@SESSIONS' => [qw/bbsroot/],
    '@FILES'    => [qw/bbsroot/],
);

1;
