package OurNet::BBS::DBI::GroupGroup;
$VERSION = "0.1";

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
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

1;
