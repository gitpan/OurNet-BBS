# $File: //depot/OurNet-BBS/BBS/CVIC/UserGroup.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::UserGroup;

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
