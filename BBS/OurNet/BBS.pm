package OurNet::BBS::OurNet::BBS;
$VERSION = "0.1";

use strict;
use OurNet::BBS::Client;

sub new { 
    return OurNet::BBS::Client->new(@_[2..$#_]);
}

1;
