package OurNet::BBS::PTT::SessionGroup;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN {__PACKAGE__->initvars()};

die "Session support at PTT now broken";

1;
