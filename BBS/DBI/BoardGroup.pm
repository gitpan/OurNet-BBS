package OurNet::BBS::DBI::BoardGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh mtime _cache/;

BEGIN {
    __PACKAGE__->initvars(
        '@packlist' => [qw/id title bm level/],
    )
};

sub refresh_meta {
    my ($self, $key) = @_;

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new({
            dbh   => $self->{dbh},
            board => $key,
        });

        return;
    }

    return if $self->timestamp(-1);

    # XXX: ALLBOARDS
    foreach my $board (my @allboards) {
        $self->{_cache}{$board} ||= $self->module('Board')->new({
            dbh   => $self->{dbh},
            board => $board,
        });
    }

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

sub STORE {
    my ($self, $key) = splice(@_, 0, 2);

    foreach my $value (@_) {
        # XXX: ACTUAL STORAGE
        %{$self->{_cache}{$key} ||= $self->module('Board', $value)->new({
            dbh   => $self->{dbh},
            board => $key,
        })} = %{$value};

        $self->timestamp(1);
    }
}

1;
