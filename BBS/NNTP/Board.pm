# $File: //depot/OurNet-BBS/BBS/NNTP/Board.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1531 $ $DateTime: 2001/08/18 01:03:39 $

package OurNet::BBS::NNTP::Board;

use strict;
use fields qw/nntp board _ego _hash/;
use OurNet::BBS;

sub refresh_articles {
    my $self = shift;

    return $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new({
	nntp  => $self->{nntp},
	board => $self->{board},
    });
}

sub refresh_archives {
    die 'no refresh_archives';
}

sub refresh_title {
    my $self = shift;
    $self->{_hash}{title} = $self->{board};
    return 1;
}

sub refresh_meta { 1 } # XXX: no meta-data yet

1;
