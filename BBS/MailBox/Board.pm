# $File: //depot/OurNet-BBS/BBS/MailBox/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1439 $ $DateTime: 2001/07/15 14:19:48 $

package OurNet::BBS::MailBox::Board;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mgr board folder _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'BoardGroup' => [qw/@packlist/],
    );
}

sub refresh_articles {
    my $self = shift;

    $self->refresh unless $self->{folder};

    return $self->{_cache}{articles} ||=
	$self->module('ArticleGroup')->new({
	    mgr		=> $self->{mgr},
	    board	=> $self->{board},
	    folder	=> $self->{folder},
	});
}

sub refresh_archives {
    die 'no refresh_archives';
}

sub refresh_meta {
    my $self = shift;

    if (!$self->{folder}) {
	$self->{folder} = $self->{mgr}->open(
	    folder => "$self->{bbsroot}/$self->{board}",
	);
    }

    $self->{_cache}{title} = $self->{folder}->name;
    $self->{_cache}{id}    = $self->{folder}->filename;
}

1;

