# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::DBI::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh mtime _cache/;

BEGIN { __PACKAGE__->initvars() };

sub refresh_meta {
    my ($self, $key) = @_;

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Group')->new({
            dbh   => $self->{dbh},
            group => $key,
        });

        return;
    }

    return if $self->timestamp(-1);

    # XXX: ALL GROUP FETCH
}

sub STORE {
    my ($self, $key) = @_;

    $self->{_cache}{$key}->refresh();

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

1;
