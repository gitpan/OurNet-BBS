# $File: //depot/OurNet-BBS/BBS/Cola/FileGroup.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1825 $ $DateTime: 2001/09/16 21:27:34 $

package OurNet::BBS::Cola::FileGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;