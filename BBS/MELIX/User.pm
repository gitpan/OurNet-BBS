package OurNet::BBS::MELIX::User;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE3::User/;
use fields qw/_cache/;
use subs qw/has_perm/;

BEGIN {__PACKAGE__->initvars()};

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

1;
