package OurNet::BBS::BBSAgent::Article;
$VERSION = "0.1";

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

    $self->{name} ||= $self->new_id();

    if (defined $self->{recno}) {
	return 0 if $self->{_cache}{header}; # already exists

        my ($ta, $tb) = $self->{bbsobj}->board_article_fetch_first(
            $self->{board}, $self->{recno}
        );

        my $body = '';

        while ($body .= $ta) {
            # put special case here
            last unless index($tb, '%') > -1;
            last if index($tb, '100%') > -1;

            ($ta, $tb) = $self->{bbsobj}->board_article_fetch_next();
        }

        my ($head, $body) = split(/$var{separator}/, $body, 2);
        my ($author, $nick, $title, $date);

        $body ||= $head; # fallback unless in expected format

        ($author, $title, $date) = map {
            $head =~ m/$var{headl}$_$var{headr}/m ? $1 : ''
        } split(',', $var{headi});

        # special-case header munging
        $date = $1 if $date   =~ m/\(([^)]*)\)/;      # embedded date
        $nick = $1 if $author =~ s/\s?\(([^)]*)\)$//; # nickname in braces

        # this should rule out most ANSI codes but not all
        $body =~ s/\015//g;         # crlf: fascist!
        $body =~ s/\012/\n/g;       # crlf: whatever way you feel comfortable
        $body =~ s/\x00//g;         # trim all nulls

        $body =~ s/\x1b\[[KHJ]//g; 
        $body =~ s/\x1b\[;H.+\n//g;
        $body =~ s/\n\x1b\[0m$//g;
        $body =~ s/\n*\x1b\[\d+;1H/\n\n/g;
        $body =~ s/\x1b\[3[26]m(.+)\x1b\[0?m/$1/g;

        $body =~ s/^\x1b\[0m\n\n//g;
        $body =~ s/\n\x1b\[0m\n\n+/\n\n/g; # this is not good. needs tuning.

        @{$self->{_cache}}{qw/title author nick body date datetime/} =
            ($title, $author, $nick, $body, time2str(
                '%y/%m/%d', str2time($date)
            ), $date);

	$author ||= 'unknown';
	$title  ||= 'unknown';
	$date   ||= 'unknown';
        
        my $from = (index($author, '@') > -1)
                   ? $author : "$author.bbs\@$self->{bbsobj}{bbsaddr}";

        $self->{_cache}{header} = {
            From         => $from,
            Subject      => $title,
            Date         => $date,
            'Message-ID' => OurNet::BBS::Utils::get_msgid(
                $date,
                $from,
                $self->{board},
                $self->{bbsobj}{bbsaddr}
            ),
        };

        $self->{bbsobj}->board_article_fetch_last();
    }

    unless (defined $self->{recno}) {
        die "Random creation of article is unimplemented.";
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    die "Modify article attributes is unimplemented.";
}

1;
