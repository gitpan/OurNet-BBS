# $File: //depot/OurNet-BBS/BBS/Firebird3/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::ArticleGroup;

use strict;
use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
use fields qw/_ego _hash _array/;
use subs qw/FETCHSIZE/;

use OurNet::BBS::Base (
    '$packstring'    => 'Z80Z80Z80N4Z12',
    '$namestring'    => 'Z80',
    '$packsize'      => 256,
    '@packlist'      => [qw/id author title level accessed/],
);

sub writeok { 0 };
sub readok { 1 };

sub FETCHSIZE {
    my $self = $_[0]->ego;

    no warnings 'uninitialized';
    return int((stat(
	join('/', @{$self}{qw/bbsroot basepath board dir name/}, '.DIR')
    ))[7] / $packsize);
}

1
