# $File: //depot/OurNet-BBS/BBS/Firebird3/BBS.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
);

1;
