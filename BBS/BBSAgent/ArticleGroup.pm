# $File: //depot/OurNet-BBS/BBS/BBSAgent/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 1839 $ $DateTime: 2001/09/18 21:08:16 $

package OurNet::BBS::BBSAgent::ArticleGroup;

use strict;
use fields qw/bbsroot bbsobj board basepath article_size _ego _hash _array/;
use OurNet::BBS::Base;

my $lastpost = 0;

sub refresh_meta {
    my ($self, $key, $flag) = @_;

    die 'hash key not implemented' if $flag == HASH;

    $self->{_ego}->FETCHSIZE;

    if (defined $key) {
        # out-of-bound check
        return if $key < 0 or $key >= $self->{article_size};
        return if $self->{_array}[$key];

        $self->{_array}[$key] = $self->module('Article')->new(
	    @{$self}{qw/bbsroot bbsobj board/}, $key + 1,
	);

        return 1;
    }

    return if $self->{article_size};

    @{$self->{_array}} = map {
        $self->module('Article')->new(
	    @{$self}{qw/bbsroot bbsobj board/}, $_,
	)
    } (0 .. $self->{article_size} - 1);

    return 1;
}

sub FETCHSIZE {
    my $self = shift->ego;

    no warnings 'numeric';
    return $self->{article_size} 
	||= int($self->{bbsobj}->board_list_last($self->{board}));
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    my $body = $value->{body};
    $body =~ s/(?<!\015)\012/\015\012/g; # crlf: sensible
    $body = "作者: $value->{header}{From} ".
            "看板: $value->{header}{Board}\015\012".
	    "標題: $value->{header}{Subject}\015\012".
	    "時間: $value->{header}{Date}\015\012\015\012".
	    $body;

    my $author = $1 if $value->{header}{From} =~ m/([^\s@]+)/;

    if ($author ne $self->{bbsobj}{var}{username}) {
        $author =~ s/\..*//;
        $author .= '.';
    }

    $self->{bbsobj}->article_post_raw(
        $self->{board}, $value->{header}{Subject}, $body, $author,
    );

    sleep 1 if (time - $lastpost) < 2; # avoids same-time posting
    $lastpost = time;

    return 1;
}

1;
