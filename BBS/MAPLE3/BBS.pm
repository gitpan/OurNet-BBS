# $File: //depot/OurNet-BBS/BBS/MAPLE3/BBS.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MAPLE3::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use subs qw/readok writeok/;
use OurNet::BBS::Base;

sub writeok { 0 }

sub readok {
    my ($self, $op, $user) = @_;

    return if (
	$user->has_perm('PERM_DENYLOGIN')
	or $user->has_perm('PERM_PURGE') and !$user->has_perm('PERM_SYSOP')
    ); 

    return 1;
}

1;
