# $File: //depot/OurNet-BBS/BBS/MELIX/User.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MELIX::User;

use base qw/OurNet::BBS::MAPLE3::User/;
use fields qw/_ego _hash/;
use subs qw/readok writeok has_perm/;
use OurNet::BBS::Base;

sub writeok { 0 }
sub readok { 1 }

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

1;

