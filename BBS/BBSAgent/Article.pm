# $File: //depot/OurNet-BBS/BBS/BBSAgent/Article.pm $ $Author: autrijus $
# $Revision: #11 $ $Change: 1215 $ $DateTime: 2001/06/19 01:21:04 $

package OurNet::BBS::BBSAgent::Article;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath name dir recno mtime btime _cache/;

use Date::Parse;
use Date::Format;

BEGIN { __PACKAGE__->initvars() }

sub new_id {
    my $self = shift;

    return int($self->{bbsobj}->board_list_last($self->{board}));
}

sub refresh_meta {
    my $self = shift;
    my %var = %{$self->{bbsobj}{var}};

    # setting up defaults
    $var{headansi}    ||= '47;34m';
    $var{headansiend} ||= '44;37m';
    $var{separator}   ||= '\x0d(?:\e\[[0-9;]+m)?(?:─)+';
    $var{headl}       ||= '\x1b\[' . $var{headansi} . ' ';
    $var{headr}       ||= ' \x1b\[' . $var{headansiend} . ' (.+?)\s*\x1b';
    $var{headi}       ||= '作者,標題,時間'; # must be in this order

    my @compiled = map { "$var{headl}$_$var{headr}" } split(',', $var{headi});

    $self->{name} ||= $self->new_id;

    if (defined $self->{recno}) {
	return if $self->{_cache}{header}; # already exists

        my ($head, $body) = split(
	    /$var{separator}/o, $self->_refresh_body, 2
	);

        $body ||= $head; # fallback unless in expected format

        my $author = $head =~ m/$compiled[0]/mo ? $1 : '';
        my $title  = $head =~ m/$compiled[1]/mo ? $1 : '';
        my $date   = $head =~ m/$compiled[2]/mo ? $1 : '';

	my $nick;

        # special-case header munging

        $date = $1 if $date   =~ m/\(([^)]*)\)/;            # embedded date
	$nick = $1 if $author =~ s/\s?\((.*?)\)?[\s\t]*$//; # nickname

	$author ||= '(unknown)';
	$title  ||= '(untitled)';
	$date   ||= scalar localtime;

	_adjust_body($body);

        @{$self->{_cache}}{qw/title author nick body date datetime/} = (
	    $title, $author, $nick, $body, time2str(
                '%y/%m/%d', str2time($date)
            ), $date,
	);

        $self->{_cache}{header} = {
            From	=> $author . (defined $nick ? " ($nick)" : ''),
            Subject	=> $title,
            Date	=> $date,
	    Board	=> $self->{board},
	};

	OurNet::BBS::Utils::set_msgid(
	    $self->{_cache}{header}, 
	    $self->{bbsobj}{bbsaddr},
	);

        $self->{bbsobj}->board_article_fetch_last;
    }

    die "Random creation of article is unimplemented."
	unless defined($self->{recno});

    return 1;
}

sub _adjust_body {
    # XXX: this should rule out most ANSI codes but not all

    $_[0] =~ s/\015//g; # cf. 'Unix brain damage' in jargon file.
    $_[0] =~ s/\x00//g; # trim all nulls

    $_[0] =~ s/\x1b\[[KHJ]//g; 
    $_[0] =~ s/\x1b\[;H.+\n//g;
    $_[0] =~ s/\n\x1b\[0m$//g;
    $_[0] =~ s/\n*\x1b\[\d+;1H/\n\n/g;
    $_[0] =~ s/\x1b\[3[26]m(.+)\x1b\[0?m/$1/g;

    $_[0] =~ s/^\x1b\[0m\n\n//g;
    $_[0] =~ s/\n\x1b\[0m\n\n+/\n\n/g; # this is not good. needs tuning.
}

sub _refresh_body {
    my ($self) = @_;
    my ($body, $chunk, $precent) = ('');

    eval {
	($chunk, $precent) = $self->{bbsobj}->board_article_fetch_first( 
	    $self->{board}, $self->{recno} 
	) 
    };

    die $self->{bbsobj}{errmsg} if $self->{bbsobj}{errmsg};

    while ($body .= $chunk) {
	# put special case here
	last unless index($precent, '%') > -1;
	last if index($precent, '100%') > -1;

	($chunk, $precent) = $self->{bbsobj}->board_article_fetch_next;
    }

    return $body;
}

sub STORE {
    my ($self, $key, $value) = @_;

    die "Modify article attributes is unimplemented.";
}

1;
