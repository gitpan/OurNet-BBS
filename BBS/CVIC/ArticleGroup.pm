# $File: //depot/OurNet-BBS/BBS/CVIC/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::CVIC::ArticleGroup;

use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
use fields qw/_cache _phash/;

BEGIN {__PACKAGE__->initvars()};

1;
