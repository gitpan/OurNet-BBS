# $File: //depot/OurNet-BBS/BBS/MELIX/User.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1136 $ $DateTime: 2001/06/14 18:12:19 $

package OurNet::BBS::MELIX::User;

use base qw/OurNet::BBS::MAPLE3::User/;
use fields qw/_cache/;
use subs qw/has_perm/;

BEGIN { __PACKAGE__->initvars() }

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

1;
