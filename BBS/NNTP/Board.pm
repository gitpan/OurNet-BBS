# $File: //depot/OurNet-BBS/BBS/NNTP/Board.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::NNTP::Board;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/nntp groupname _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'BoardGroup' => [qw/@packlist/],
    );
}

sub refresh_articles {
    my $self = shift;

    return $self->{_cache}{articles} ||=
	$self->module('ArticleGroup')->new({
	    nntp	=> $self->{nntp},
	    groupname	=> $self->{groupname},
	});
}

sub refresh_archives {
    die 'no refresh_archives';
}

sub refresh_meta { 1 } # XXX: no meta-data yet

1;

