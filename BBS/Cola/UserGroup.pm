# $File: //depot/OurNet-BBS/BBS/Cola/UserGroup.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1825 $ $DateTime: 2001/09/16 21:27:34 $

package OurNet::BBS::Cola::UserGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::UserGroup/;
use fields qw/_ego _hash _array/;

use OurNet::BBS::Base;

sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;

    return ($param->[0] eq $user->id);
}


1;
