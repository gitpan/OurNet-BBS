# $File: //depot/OurNet-BBS/BBS/RAM/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1662 $ $DateTime: 2001/09/02 05:54:09 $

package OurNet::BBS::RAM::SessionGroup;

use strict;
use fields qw/dbh chatport _ego _hash/;

use OurNet::BBS::Base (
    '@packlist' => [ qw/pid uid msgs username from/ ],
);

sub STORE {
    my ($self, $key, $value) = @_;

    # XXX: SESSION STORE
}

1;
