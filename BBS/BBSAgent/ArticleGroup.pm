# $File: //depot/OurNet-BBS/BBS/BBSAgent/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1215 $ $DateTime: 2001/06/19 01:21:04 $

package OurNet::BBS::BBSAgent::ArticleGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath _cache _phash/;

BEGIN { __PACKAGE__->initvars() }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

    die 'hash key not implemented (!)' if $key and !$arrayfetch;

    $self->FETCHSIZE();

    if ($key) {
        # out-of-bound check
        return if $key < 1 or $key > $self->{_cache}{_article_last};
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module('Article')->new(
                $self->{bbsobj},
                $self->{board},
                $self->{basepath},
                $key,
                '',
                $key,
            );

        $self->{_phash}[0][0]{$key} = $key;
        $self->{_phash}[0][$key] = $obj;
        return 1;
    }

    return 0 if $self->{_cache}{_article_last};

    local $_;
    $self->{_phash}[0] = fields::phash(map {
        # return the thing
        ($_, $self->module('Article')->new(
                $self->{bbsobj},
                $self->{board},
                $self->{basepath},
                $_,
                "",
                $_,
        ));
    } (1..$self->{_cache}{_article_last}));

    return 1;
}

sub FETCHSIZE {
    my $self = $_[0];

    no warnings 'numeric';
    $self->{_cache}{_article_last} 
	||= int($self->{bbsobj}->board_list_last($self->{board}));

    return $self->{_cache}{_article_last} + 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $body = $value->{body};

    $body =~ s/\015?\012/\015\012/g; # crlf: sensible
    $body = "作者: $value->{header}{From} ".
            "看板: $value->{header}{Board}\015\012".
	    "標題: $value->{header}{Subject}\015\012".
	    "時間: $value->{header}{Date}\015\012\015\012".
	    $body;

    use Mail::Address;
    my $author = (Mail::Address->parse($value->{header}{From}))[0]->user;

    if ($author ne $self->{bbsobj}{var}{username}) {
        $author =~ s/\..*//;
        $author .= '.';
    }

    $self->{bbsobj}->article_post_raw(
        $self->{board},
	$value->{header}{Subject},
	$body,
	$author,
    );

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});
}

1;
