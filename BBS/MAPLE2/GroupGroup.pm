# $File: //depot/OurNet-BBS/BBS/MAPLE2/GroupGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::MAPLE2::GroupGroup;

# do we have group in standard maple2??

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/_cache/;

sub refresh_meta {
    die 'Group for MAPLE2 not implemented.';
}

1;
