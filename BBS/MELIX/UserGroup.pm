package OurNet::BBS::MELIX::UserGroup;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE3::UserGroup/;
use fields qw/_cache _phash/;

BEGIN {__PACKAGE__->initvars()};

1;
