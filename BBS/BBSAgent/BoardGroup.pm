# $File: //depot/OurNet-BBS/BBS/BBSAgent/BoardGroup.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1131 $ $DateTime: 2001/06/14 16:30:21 $

package OurNet::BBS::BBSAgent::BoardGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot bbsobj mtime _cache/;

BEGIN { __PACKAGE__->initvars() }

sub refresh_meta {
    my ($self, $key) = @_;

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new(
	    $self->{bbsobj}, $key
        );
        return;
    }

    die 'board listing not implemented';
}

1;
