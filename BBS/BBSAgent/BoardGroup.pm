# $File: //depot/OurNet-BBS/BBS/BBSAgent/BoardGroup.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 1542 $ $DateTime: 2001/08/19 03:33:19 $

package OurNet::BBS::BBSAgent::BoardGroup;

use strict;
use fields qw/bbsroot bbsobj mtime _ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    die 'board listing not implemented' unless $key;

    $self->{_hash}{$key} ||= $self->module('Board')->new(
	@{$self}{qw/bbsroot bbsobj/}, $key,
    );

    return 1;
}

1;
