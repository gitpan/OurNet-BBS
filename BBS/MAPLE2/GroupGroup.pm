# $File: //depot/OurNet-BBS/BBS/MAPLE2/GroupGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1267 $ $DateTime: 2001/06/23 20:35:33 $

package OurNet::BBS::MAPLE2::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/_cache/;

BEGIN { __PACKAGE__->initvars() }

sub refresh_meta {
    die 'Group for MAPLE2 not implemented.';
}

1;
