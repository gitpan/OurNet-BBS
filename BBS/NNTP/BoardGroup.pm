# $File: //depot/OurNet-BBS/BBS/NNTP/BoardGroup.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1531 $ $DateTime: 2001/08/18 01:03:39 $

package OurNet::BBS::NNTP::BoardGroup;

use strict;
use fields qw/bbsroot nntp _ego _hash/;
use OurNet::BBS::Base;

use Net::NNTP;

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{nntp} ||= Net::NNTP->new(
	$self->{bbsroot},
	Debug => $OurNet::BBS::DEBUG,
    ) or die $!;

    my @keys = (defined $key ? $key : keys(%{$self->{nntp}->list}));

    foreach $key (@keys) {
	$self->{_hash}{$key} ||= $self->module('Board')->new({
	    nntp  => $self->{nntp},
	    board => $key,
	});
    }

    return 1;
}

1;
