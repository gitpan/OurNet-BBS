# $File: //depot/OurNet-BBS/BBS/MailBox/Article.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1439 $ $DateTime: 2001/07/15 14:19:48 $

package OurNet::BBS::MailBox::Article;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/mgr board folder name recno _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'ArticleGroup' => [qw/@packlist/],
    );
}

sub new_id { }

sub refresh_body {
    my $self = shift;
    return if $self->{_cache}{body};

    $self->{_cache}{body} = join(
	'', @{$self->{folder}->message($self->{recno})->body}
    );
}

sub refresh_header { 
    my $self = shift;
    return if $self->{_cache}{header};

    my $head = $self->{folder}->message($self->{recno})->head;

    $self->{_cache}{header} = { 
	map { $_ => substr(join('', $head->get($_)), 0, -1) } 
	map { $_ eq 'Message-Id' ? 'Message-ID' : $_ } 
	keys %{$head->{mail_hdr_hash}} 
    };
}

sub refresh_meta {
    my $self = shift;

    $self->refresh_header;

    $self->{_cache}{author} = $self->{_cache}{header}{From};
    $self->{_cache}{title}  = $self->{_cache}{header}{Subject};
    $self->{_cache}{board}  = $self->{_cache}{header}{Board} = $self->{board};

    1;
}

sub STORE {
    die 'no Article STORE yet';
}

1;
