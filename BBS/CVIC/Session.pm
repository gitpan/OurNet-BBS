# $File: //depot/OurNet-BBS/BBS/CVIC/Session.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::Session;

use strict;
use base qw/OurNet::BBS::MAPLE2::Session/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
