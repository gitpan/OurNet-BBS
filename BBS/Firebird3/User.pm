# $File: //depot/OurNet-BBS/BBS/Firebird3/User.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3004 $ $DateTime: 2002/02/04 15:42:16 $

package OurNet::BBS::Firebird3::User;

use strict;
use base qw/OurNet::BBS::MAPLE2::User/;
use fields qw/_ego _hash/;
use subs qw/refresh_mailbox/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

sub refresh_mailbox {
    my $self = shift;

    $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new(
	$self->{bbsroot},
	$self->{id},
	"mail/".uc(substr($self->{id}, 0, 1)),
    );
}


1;
