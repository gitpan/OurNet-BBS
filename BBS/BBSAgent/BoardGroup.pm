package OurNet::BBS::BBSAgent::BoardGroup;
$VERSION = "0.1";

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
