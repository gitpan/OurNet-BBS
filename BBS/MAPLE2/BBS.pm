package OurNet::BBS::MAPLE2::BBS;

$VERSION = '0.01';

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;

BEGIN { __PACKAGE__->initvars() }

1;
