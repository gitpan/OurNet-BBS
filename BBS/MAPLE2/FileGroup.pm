# $File: //depot/OurNet-BBS/BBS/MAPLE2/FileGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1270 $ $DateTime: 2001/06/24 07:15:18 $

package OurNet::BBS::MAPLE2::FileGroup;

use strict;
use warnings;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot _cache/;
use subs qw/readok/;

BEGIN { 
    __PACKAGE__->initvars(
	'$PATH_ETC' => 'etc',
    ) 
}

sub readok { 1 }

sub refresh_meta {
    my ($self, $key) = @_;

    if ($key) {
        # hash key -- no recaching needed
        return if $self->{_cache}{$key};

	require OurNet::BBS::ScalarFile;
	tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile', 
	    "$self->{bbsroot}/$PATH_ETC/$key";

	return 1;
    }

    die "globbing the etc directory considered harmful.";
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';

    require OurNet::BBS::ScalarFile;
    tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile', 
	"$self->{bbsroot}/$PATH_ETC/$key";

    $self->{_cache}{$key} = $value;
}

sub EXISTS {
    my ($self, $key) = @_;

    return -e ("$self->{bbsroot}/$PATH_ETC/$key");
}

1;
