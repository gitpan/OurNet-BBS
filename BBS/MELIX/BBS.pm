# $File: //depot/OurNet-BBS/BBS/MELIX/BBS.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;
use subs qw/readok writeok/;

BEGIN { __PACKAGE__->initvars() }

sub writeok { 0 }

sub readok {
    my ($self, $user) = @_;

    return 1 if $user->has_perm('PERM_SYSOP');
    
    return if (
	$user->has_perm('PERM_DENYLOGIN') or $user->has_perm('PERM_PURGE')
    );

    return 1;
}

1;
