# $File: //depot/OurNet-BBS/BBS/CVIC/FileGroup.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1954 $ $DateTime: 2001/10/02 13:05:22 $

package OurNet::BBS::CVIC::FileGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use subs qw/writeok readok/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
