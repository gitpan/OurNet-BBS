# $File: //depot/OurNet-BBS/BBS/MailBox/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1439 $ $DateTime: 2001/07/15 14:19:48 $

package OurNet::BBS::MailBox::BoardGroup;

use strict;
use Mail::Box::Manager;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot dummy mgr _cache/;

BEGIN {
    __PACKAGE__->initvars(
        '@packlist' => [qw/id title bm level/],
    )
};

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{mgr} ||= Mail::Box::Manager->new or die $!;

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new({
	    bbsroot	=> $self->{bbsroot},
	    mgr		=> $self->{mgr},
	    board	=> $key,
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
