# $File: //depot/OurNet-BBS/BBS/MAPLE3/UserGroup.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MAPLE3::UserGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot maxuser _cache _phash/;
use subs qw/writeok readok/;
use open IN => ':raw', OUT => ':raw';

BEGIN { __PACKAGE__->initvars() }

sub writeok { 0 }
sub readok { 1 }

sub FETCHSIZE {
    my $self = $_[0];

    return (stat("$self->{bbsroot}/.USR"))[7] / 16;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;
    my $name;

    if ($key) {
        if (length($key) and $arrayfetch) {
            # array fetch
            open my $DIR, "$self->{bbsroot}/.USR";
            seek $DIR, ($key - 1) * 16 + 4, 0;
            read $DIR, $name, 12;
            $name = unpack('Z14', $name);
            close $DIR;
            return if $self->{_phash}[0][0]{$name} == $key;
        }
        elsif ($key) {
            # key fetch
            $name = $key;
            return if $self->{_phash}[0][0]{$key};
            $key = 0;
        }
    }

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key, # XXX -1?
    );

    $key ||= $obj->{userno};

    $self->{_phash}[0][0]{$name} = $key;
    $self->{_phash}[0][$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $obj;

    $obj = $self->module('User', $value)->new($self->{bbsroot}, $key);

    while (my ($k, $v) = each %{$value}) {
        $obj->{$k} = $v unless $k eq 'id';
    };

    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists ($self->{_cache}{$key}) or -d "$self->{bbsroot}/usr/".lc(
	substr($self->{id}, 0, 1)
    )."/$self->{id}";
}

1;
