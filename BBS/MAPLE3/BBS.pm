package OurNet::BBS::MAPLE3::BBS;

$VERSION = '0.01';

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _cache/;

BEGIN { __PACKAGE__->initvars() }

sub writeok { 0 };

sub readok {
    my ($self, $op, $user) = @_;

    return if ($user->has_perm('PERM_DENYLOGIN') 
	    or $user->has_perm('PERM_PURGE')
	    and !user->has_perm('PERM_SYSOP')); 

    return 1;
}

1;
