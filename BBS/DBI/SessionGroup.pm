package OurNet::BBS::DBI::SessionGroup;
$VERSION = "0.1";

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
