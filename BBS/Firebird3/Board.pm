# $File: //depot/OurNet-BBS/BBS/Firebird3/Board.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::Board;

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
