package OurNet::BBS::DBI::UserGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh _cache _phash/;

BEGIN { __PACKAGE__->initvars() };

sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;
    my $name;

    if ($arrayfetch) {
        # XXX: ARRAY FETCH
        return if $self->{_phash}[0][0]{$name} == $key;
    }
    elsif ($key) {
        # XXX: KEY FETCH
        $name = $key;
        return if $self->{_phash}[0][0]{$name};
        $key = 0;
    }
    else {
        # XXX: GLOBAL FETCH
    }

    my $obj = $self->module('User')->new({
        dbh   => $self->{dbh},
        id    => $name,
        recno => $key,
    });

    $key ||= $obj->{userno};

    $self->{_phash}[0][0]{$name} = $key;
    $self->{_phash}[0][$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    %{$self->module('User', $value)->new({
        dbh => $self->{dbh},
        id  => $key
    })} = %{$value};

    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: USER EXISTS
    return exists ($self->{_cache}{$key});
}

1;
