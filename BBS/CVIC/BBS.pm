# $File: //depot/OurNet-BBS/BBS/CVIC/BBS.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS::Base (
    '@GROUPS'   => [qw/bbsroot _ego/], # cheat!
);

1;
