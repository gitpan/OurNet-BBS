# $File: //depot/OurNet-BBS/BBS/MELIX/User.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1387 $ $DateTime: 2001/07/09 16:40:39 $

package OurNet::BBS::MELIX::User;

use base qw/OurNet::BBS::MAPLE3::User/;
use fields qw/_cache/;
use subs qw/has_perm writeok readok/;

BEGIN { __PACKAGE__->initvars() }

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

sub writeok { 0 }
sub readok { 1 }

1;

