# $File: //depot/OurNet-BBS/BBS/CVIC/BBS.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1595 $ $DateTime: 2001/08/29 20:28:55 $

package OurNet::BBS::CVIC::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS::Base (
    '@GROUPS'   => [qw/bbsroot _ego/], # cheat!
);

1;