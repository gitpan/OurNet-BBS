# $File: //depot/OurNet-BBS/BBS/MailBox/Article.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MailBox::Article;

use strict;
use fields qw/mgr board folder name recno _ego _hash/;
use OurNet::BBS::Base;

sub refresh_body {
    my $self = shift;
    return if defined $self->{_hash}{body};

    $self->{_hash}{body} = join(
	'', @{$self->{folder}->message($self->{recno})->body}
    );
}

sub refresh_header { 
    my $self = shift;
    return if $self->{_hash}{header};

    my $head = $self->{folder}->message($self->{recno})->head;

    $self->{_hash}{header} = { 
	map { $_ => substr(join('', $head->get($_)), 0, -1) } 
	map { $_ eq 'Message-Id' ? 'Message-ID' : $_ } 
	keys %{$head->{mail_hdr_hash}} 
    };
}

sub refresh_meta {
    my $self = shift;

    $self->refresh_header;

    $self->{_hash}{author} = $self->{_hash}{header}{From};
    $self->{_hash}{title}  = $self->{_hash}{header}{Subject};
    $self->{_hash}{board}  = $self->{_hash}{header}{Board} = $self->{board};

    1;
}

sub STORE {
    die 'no Article STORE yet';
}

1;
