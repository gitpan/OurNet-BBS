package OurNet::BBS::PlClient::BBS;
$VERSION = "0.1";

use strict;
use OurNet::BBS::PlClient;

sub new { return OurNet::BBS::PlClient->new(@_[1..$#_]) }

1;
