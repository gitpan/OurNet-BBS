# $File: //depot/OurNet-BBS/BBS/Firebird3/BoardGroup.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::BoardGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_ego _hash/;

use OurNet::BBS::Base (
    '$packstring'    => 'Z80Z20Z60Z1Z79LZ12',
    '$namestring'    => 'Z80',
    '$packsize'      => 256,
    '@packlist'      => [
	qw/id owner bm flag title level accessed/, # XXX
    ],
    '$BRD'           => '.BOARDS',
    '$PATH_BRD'      => 'boards',
    '$PATH_GEM'      => '0Announce/.Search', # XXX: drastically different
);

sub writeok { 0 };
sub readok { 1 };

1;
