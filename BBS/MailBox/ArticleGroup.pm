# $File: //depot/OurNet-BBS/BBS/MailBox/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MailBox::ArticleGroup;

use strict;
use fields qw/mgr board folder _ego _array/;
use OurNet::BBS::Base;

# FIXME: use first/last update to determine refresh result

sub refresh_meta {
    my ($self, $key) = @_;

    die "$key out of range" if $key >= $self->{folder}->messages;

    $self->{_array}[$key] = $self->module('Article')->new({
	mgr	=> $self->{mgr},
	board	=> $self->{board},
	folder	=> $self->{folder},
	recno	=> $key,
    });
}

1;
