# $File: //depot/OurNet-BBS/BBS/Cola/Board.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1825 $ $DateTime: 2001/09/16 21:27:34 $

package OurNet::BBS::Cola::Board;

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;
    my $id = quotemeta($user->id);

    return ($self->{bm} =~ /\b$id\b/s) if $param->[0] eq 'archives';

    return 1;
}

1;
