# $File: //depot/OurNet-BBS/BBS/NNTP/Board.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 2234 $ $DateTime: 2001/11/01 14:57:59 $

package OurNet::BBS::NNTP::Board;

use strict;
use fields qw/nntp board _ego _hash/;
use OurNet::BBS::Base;

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

sub refresh_id {
    my $self = shift;

    $self->{_hash}{id} = $self->{board};
    return 1;
}

sub refresh_title {
    my $self  = shift;
    my $board = $self->{board};

    $self->{_hash}{title} = $self->{nntp}->newsgroups($board)->{$board};
    return 1;
}

sub refresh_meta { 1 } # XXX: no meta-data yet

1;
