# $File: //depot/OurNet-BBS/BBS/MAPLE3/FileGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MAPLE3::FileGroup;

use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$PATH_ETC' => 'gem/@',
);

1;
