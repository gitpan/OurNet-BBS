package OurNet::BBS::BBSAgent::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath _cache _phash/;

BEGIN { __PACKAGE__->initvars() }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    if ($key and $key ne int($key)) {
        # hash key -- no recaching needed
        die 'hash key not implemented (!)';
    }

    $self->FETCHSIZE();

    if ($key) {
        # out-of-bound check
        local $^W = 0; # usage of int() below is voluntary
        return if $key < 1 or $key > $self->{_cache}{_article_last};
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module('Article')->new(
                $self->{bbsobj},
                $self->{board},
                $self->{basepath},
                $key,
                "",
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

    local $^W; # usage of int() below is voluntary

    $self->{_cache}{_article_last} 
	||= int($self->{bbsobj}->board_list_last($self->{board}));

    return $self->{_cache}{_article_last} + 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $body = $value->{body};
    $body =~ s/\x0d?\x0a/\x0d\x0a/g;
    $body = << ".";
作者: $value->{header}{From} 看板: $value->{header}{Board}\r\n標題: $value->{header}{Subject}\r\n時間: $value->{header}{Date}\r\n\r\n$body
.
    use Mail::Address;
    my $author = (Mail::Address->parse($value->{header}{From}))[0]->user;

    if ($author ne $self->{bbsobj}{var}{username}) {
        $author =~ s/\..*//;
        $author .= '.';
    }
    # We still need to fake remote article headers.
=comment
    else {
        $author = ''; # no need to change author
    }
=cut

    $self->{bbsobj}->article_post_raw(
        $self->{board},
	    $value->{header}{Subject},
	    $body,
	    $author,
	);
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});
}

1;
