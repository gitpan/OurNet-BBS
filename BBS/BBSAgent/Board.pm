# $File: //depot/OurNet-BBS/BBS/BBSAgent/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1131 $ $DateTime: 2001/06/14 16:30:21 $

package OurNet::BBS::BBSAgent::Board;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board recno mtime _cache/;

# TODO: vote, man, note, etc...

BEGIN { __PACKAGE__->initvars() }

sub refresh_articles {
    my $self = shift;

    require OurNet::BBS::BBSAgent::ArticleGroup;

    return $self->{_cache}{articles} ||=
        OurNet::BBS::BBSAgent::ArticleGroup->new(
            $self->{bbsobj}, $self->{board}, 'article'
        );
}

sub refresh_archives {
    die 'archive not implemented';
}

sub refresh_meta {
    die 'metadata not implemented';
}

sub STORE {
    die 'storage not implemented (!)';
}

1;
