# $File: //depot/OurNet-BBS/BBS/NNTP/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::NNTP::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;

BEGIN { __PACKAGE__->initvars() }

1;
