# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::DBI::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;

BEGIN { __PACKAGE__->initvars() }

1;
