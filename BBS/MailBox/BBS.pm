# $File: //depot/OurNet-BBS/BBS/MailBox/BBS.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MailBox::BBS;

use strict;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS;

1;
