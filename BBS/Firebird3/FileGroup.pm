# $File: //depot/OurNet-BBS/BBS/Firebird3/FileGroup.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::FileGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
