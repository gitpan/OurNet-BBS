# $File: //depot/OurNet-BBS/BBS/BBSAgent/Board.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1542 $ $DateTime: 2001/08/19 03:33:19 $

package OurNet::BBS::BBSAgent::Board;

use strict;
use fields qw/bbsroot bbsobj board _ego _hash/;
use OurNet::BBS::Base;

sub refresh_articles {
    my $self = shift;

    $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new(
	@{$self}{qw/bbsroot bbsobj board/}, 'articles',
    );

    return 1;
}

sub refresh_archives {
    die 'archive not implemented';
}

sub refresh_meta {
    die 'metadata not implemented';
}

sub STORE {
    die 'storage not implemented';
}

1;
