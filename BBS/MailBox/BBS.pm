# $File: //depot/OurNet-BBS/BBS/MailBox/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1439 $ $DateTime: 2001/07/15 14:19:48 $

package OurNet::BBS::MailBox::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;

BEGIN { __PACKAGE__->initvars() }

1;
