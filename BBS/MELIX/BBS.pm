# $File: //depot/OurNet-BBS/BBS/MELIX/BBS.pm $ $Author: clkao $
# $Revision: #6 $ $Change: 2392 $ $DateTime: 2001/11/22 13:41:47 $

package OurNet::BBS::MELIX::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              chatport passwd _ego _hash/;
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
