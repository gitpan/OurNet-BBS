package OurNet::BBS::MELIX::BBS;

$VERSION = '0.01';

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
    
    return if ($user->has_perm('PERM_DENYLOGIN') 
	    or $user->has_perm('PERM_PURGE'));

    return 1;
}

1;
