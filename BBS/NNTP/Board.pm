package OurNet::BBS::NNTP::Board;
$VERSION = "0.1";

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

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new
	({
	  nntp		=> $self->{nntp},
	  groupname	=> $self->{groupname},
	 });
}

sub refresh_archives {
    die 'no refresh_archives';
}

sub refresh_meta {
    my ($self, $key) = @_;

    # XXX: no meta-data yet
    @{$self->{_cache}}{@packlist} = () if 0;

    return 1;
}

sub STORE {
    die 'no Board STORE';
}

1;

