# $File: //depot/OurNet-BBS/BBS/BBSAgent/Article.pm $ $Author: clkao $
# $Revision: #16 $ $Change: 1747 $ $DateTime: 2001/09/08 02:48:31 $

package OurNet::BBS::BBSAgent::Article;

use strict;
use fields qw/bbsroot bbsobj board recno basepath name _ego _hash/;
use OurNet::BBS::Base;

use Date::Parse;
use Date::Format;

sub new_id {
    my $self = shift;
    return int($self->{bbsobj}->board_list_last($self->{board})) - 1;
}

sub refresh_meta {
    my $self = shift;

    # setting up defaults
    my %var = %{$self->{bbsobj}{var}};
    $var{headansi}    ||= '47;34m';
    $var{headansiend} ||= '44;37m';
    $var{separator}   ||= '\x0d(?:\e\[[0-9;]+m)?(?:─)+';
    $var{headl}       ||= '\x1b\[' . $var{headansi} . ' ';
    $var{headr}       ||= ' \x1b\[' . $var{headansiend} . ' (.+?)\s*\x1b';
    $var{headi}       ||= '作者,標題,時間'; # must be in this order

    my @compiled = map { "$var{headl}$_$var{headr}" } split(',', $var{headi});

    $self->{name} ||= $self->new_id;

    if (defined $self->{recno}) {
	return if $self->{_hash}{header}; # already exists

        my ($head, $body) = split(
	    /$var{separator}/, $self->_fetch_body, 2
	);

        $body ||= $head; # fallback unless in expected format

        my $author = $head =~ m/$compiled[0]/m ? $1 : '';
        my $title  = $head =~ m/$compiled[1]/m ? $1 : '';
        my $date   = $head =~ m/$compiled[2]/m ? $1 : '';

	my $nick;

        # special-case header munging

        $date = $1 if $date   =~ m/\(([^)]*)\)/;            # embedded date
	$date =~ s/(年|月|日)/\x20/g;			    # kludge
	$date = $1 if $date =~ m/([\w\s\d:]+)/;             # strip shit
	$nick = $1 if $author =~ s/\s?\((.*?)\)?[\s\t]*$//; # nickname

	$author ||= '(unknown)';
	$title  ||= '(untitled)';
	$date   ||= scalar localtime;

	_adjust_body($body);

        @{$self->{_hash}}{qw/title author nick body date datetime/} = (
	    $title, $author, $nick, $body, time2str(
                '%y/%m/%d', str2time($date)
            ), $date,
	);

        $self->{_hash}{header} = {
            From	=> $author . (defined $nick ? " ($nick)" : ''),
            Subject	=> $title,
            Date	=> $date,
	    Board	=> $self->{board},
	};

	OurNet::BBS::Utils::set_msgid(
	    $self->{_hash}{header}, 
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

    $_[0] =~ tr/\015\x00//d; # cf. 'Unix brain damage' in jargon file.

    $_[0] =~ s/\x1b\[[KHJ]//g; 
    $_[0] =~ s/\x1b\[;H.+\n//g;
    $_[0] =~ s/\n\x1b\[0m$//g;
    $_[0] =~ s/\n*\x1b\[\d+;1H/\n\n/g;
    $_[0] =~ s/\x1b\[3[26]m(.+)\x1b\[0?m/$1/g;

    $_[0] =~ s/^\x1b\[0m\n\n//g;
    $_[0] =~ s/\n\x1b\[0m\n\n+/\n\n/g; # this is not good. needs tuning.
}

sub _fetch_body {
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

    die "modification of article attributes is unimplemented.";
}

1;
