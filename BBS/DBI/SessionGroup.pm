# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::DBI::SessionGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh chatport _cache/;

BEGIN {
    __PACKAGE__->initvars(
        '@packlist' => [ qw/pid uid msgs username from/ ],
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    # XXX: SESSION STORE
}

1;
