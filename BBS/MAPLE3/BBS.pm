# $File: //depot/OurNet-BBS/BBS/MAPLE3/BBS.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 2440 $ $DateTime: 2001/11/27 15:38:54 $

package OurNet::BBS::MAPLE3::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              chatport passwd _ego _hash/;
use subs qw/readok writeok/;

use OurNet::BBS::Base (
    '@USERS' => [qw/bbsroot/],
);

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
