# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::DBI::Group;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh group mtime _cache/;

BEGIN { __PACKAGE__->initvars() };

sub refresh_meta {
    my ($self, $key) = @_;

    return unless $self->{group};
    return if $self->timestamp(1);

    # XXX: GROUP FETCH
    return 1;
}

sub DELETE {
    my ($self, $key) = @_;

    $self->refresh($key);
    return unless delete($self->{_cache}{$key});
    
    # XXX: GROUP DELETE
    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    return if exists $self->{_cache}{$key}; # doesn't make sense yet
    
    # XXX: GROUP STORE
    $self->{_cache}{$key} = $self->module('Board')->new({
        dbh   => $self->{dbh},
        board => $key,
    });

    return 1;
}

sub remove {
    my $self = shift;

    # XXX: GROUP REMOVE
    return 1;
}

1;
