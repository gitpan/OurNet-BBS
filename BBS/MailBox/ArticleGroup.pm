# $File: //depot/OurNet-BBS/BBS/MailBox/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1439 $ $DateTime: 2001/07/15 14:19:48 $

package OurNet::BBS::MailBox::ArticleGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/mgr board folder _cache _phash/;

# FIXME: use first/last update to determine refresh result

BEGIN {
    __PACKAGE__->initvars(
        '@packlist'   => [qw//],
    );
}

sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

    if ($arrayfetch) {
        die "$key out of range" if $key > $self->{folder}->messages;

        my $obj = $self->module('Article')->new({
	    mgr		=> $self->{mgr},
	    board	=> $self->{board},
	    folder	=> $self->{folder},
	    recno	=> $key - 1
	});

        $self->{_phash}[0][0]{$key} = $key;
        $self->{_phash}[0][$key] = $obj;
    }
    elsif ($key) {
	# XXX: should fetch by message-id
	die 'no key fetch yet';
    }
}

sub STORE { }

sub EXISTS {
    my ($self, $key) = @_;

    return 1 if exists ($self->{_cache}{$key});
}

1;
