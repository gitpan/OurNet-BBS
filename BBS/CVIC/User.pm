# $File: //depot/OurNet-BBS/BBS/CVIC/User.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::User;

use strict;
use base qw/OurNet::BBS::MAPLE2::User/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
