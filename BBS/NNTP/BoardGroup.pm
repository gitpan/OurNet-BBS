# $File: //depot/OurNet-BBS/BBS/NNTP/BoardGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::NNTP::BoardGroup;

use strict;
use Net::NNTP;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot dummy nntp _cache/;

BEGIN {
    __PACKAGE__->initvars(
        '@packlist' => [qw/id title bm level/],
    )
};

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{nntp} ||= Net::NNTP->new($self->{bbsroot}) or die $!;

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new({
	    nntp	=> $self->{nntp},
	    groupname	=> $key,
        });

        return 1;
    }

    return if $self->timestamp(-1);

    # XXX: ALLBOARDS
    die "no list board yet";
}

sub EXISTS {
    my ($self, $key) = @_;

    return 1 if exists ($self->{_cache}{$key});
}

1;
