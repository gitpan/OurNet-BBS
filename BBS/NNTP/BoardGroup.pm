package OurNet::BBS::NNTP::BoardGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot dummy nntp _cache/;
use Net::NNTP;
BEGIN {
    __PACKAGE__->initvars(
        '@packlist' => [qw/id title bm level/],
    )
};

sub refresh_meta {
    my ($self, $key) = @_;
    $self->{nntp} ||= Net::NNTP->new($self->{bbsroot}) or die $!;
    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new
	    ({
	      nntp	=> $self->{nntp},
	      groupname	=> $key,
        });

        return 1;
    }

    return if $self->timestamp(-1);

    # XXX: ALLBOARDS
    die "no list board yet";
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

sub STORE {
    die "no STORE BoardGroup";
}

1;
