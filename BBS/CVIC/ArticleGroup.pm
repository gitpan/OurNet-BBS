# $File: //depot/OurNet-BBS/BBS/CVIC/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1706 $ $DateTime: 2001/09/05 04:27:10 $

package OurNet::BBS::CVIC::ArticleGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
use fields qw/_ego _hash _array/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
