package OurNet::BBS::DBI::User;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh id recno _cache/;
use File::stat;

BEGIN {
    __PACKAGE__->initvars(
        '@packlist'   => [
            qw/uid name passwd realname userlevel email/ # username?
        ],
    );
}

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{_cache}{uid}  ||= $self->{recno} - 1;
    $self->{_cache}{name} ||= $self->{id};
    return if exists $self->{_cache}{$key};

    # XXX: USER FETCH
    @{$self->{_cache}}{@packlist} = () if 0;

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    # XXX: MAILBOX
    $self->{_cache}{mailbox} ||= $self->module('ArticleGroup')->new({
        dbh   => $self->{dbh},
        board => $self->{name},
        name  => 'mailbox',
    });
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return 1;
}

1;
