# $File: //depot/OurNet-BBS/BBS/PTT/BBS.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::PTT::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS::Base;

1;
