package OurNet::BBS::DBI::Session;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/recno chatport _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'SessionGroup' => [qw/@packlist/],
    );
}

sub refresh_meta {
    my ($self, $key) = @_;

    # XXX SESSION READ
}

sub refresh_chat {
    my $self = shift;

    # XXX SESSION CHAT
}

sub remove {
    my $self = shift;

    # XXX SESSION REMOVE
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($key eq 'msg') {
        # XXX SESSION MSG
	}
    elsif ($key eq 'cb_msg') {
        # XXX SESSION CALLBACK
    }

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return unless $self->contains($key);
    # XXX SESSION UPDATE
}

sub DESTROY {
    my $self = shift;

    # XXX SESSION DESTROY
    return unless $self->{_cache}{flag};
}

1;