# $File: //depot/OurNet-BBS/BBS/MailBox/BoardGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MailBox::BoardGroup;

use strict;

use Mail::Box::Manager;
use fields qw/bbsroot mgr _ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    die "no list board yet" unless defined $key;

    $self->{mgr} ||= Mail::Box::Manager->new or die $!;

    return $self->{_hash}{$key} ||= $self->module('Board')->new({
	bbsroot	=> $self->{bbsroot},
	mgr		=> $self->{mgr},
	board	=> $key,
    });
}

1;
