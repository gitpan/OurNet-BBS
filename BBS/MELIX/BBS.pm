# $File: //depot/OurNet-BBS/BBS/MELIX/BBS.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MELIX::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use subs qw/readok writeok/;
use OurNet::BBS::Base;

sub writeok { 1 }

sub readok {
    my ($self, $user) = @_;

    return 1 if $user->has_perm('PERM_SYSOP');
    
    return if (
	$user->has_perm('PERM_DENYLOGIN') or $user->has_perm('PERM_PURGE')
    );

    return 1;
}

1;
