# $File: //depot/OurNet-BBS/BBS/MailBox/BBS.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1819 $ $DateTime: 2001/09/16 20:02:51 $

package OurNet::BBS::MailBox::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
);

1;
