# $File: //depot/OurNet-BBS/BBS/CVIC/Board.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 1715 $ $DateTime: 2001/09/05 06:21:55 $

package OurNet::BBS::CVIC::Board;

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;
    my $id = quotemeta($user->id);

    return if $self->{access} and $self->{access} !~ /\b$id\b/s;
    return ($self->{bm} =~ /\b$id\b/s) if $param->[0] eq 'archives';

    return 1;
}

1;
