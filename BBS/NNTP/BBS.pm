# $File: //depot/OurNet-BBS/BBS/NNTP/BBS.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1531 $ $DateTime: 2001/08/18 01:03:39 $

package OurNet::BBS::NNTP::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot nntp _ego _hash/;

use OurNet::BBS::Base (
    '@BOARDS' => [qw/bbsroot nntp/],
);

1;
