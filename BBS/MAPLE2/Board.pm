# $File: //depot/OurNet-BBS/BBS/MAPLE2/Board.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::MAPLE2::Board;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board shmid shm recno mtime _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'BoardGroup' => [
	    qw/$BRD $PATH_BRD $PATH_GEM $packsize $packstring @packlist/
	],
    );
}

sub refresh_articles {
    my $self = shift;

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot}, $self->{board}, $PATH_BRD
    );
}

sub refresh_archives {
    my $self = shift;

    return $self->{_cache}{archives} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot}, $self->{board}, $PATH_GEM
    );
}

sub post_new_board {};

sub refresh_meta {
    my ($self, $key) = @_;
    die 'cannot parse board' unless $self->{board};

    if ($key and index(
	" forward anonymous permit anonymous access etc_brief ".
	" maillist overrides reject water note friendplan",
	" $key "
    ) > -1) {
	# special-casing MAPLE2 note => notes:
	$key = 'notes' if $key eq 'note' and $PATH_BRD eq 'boards';

        return if exists $self->{_cache}{$key};

        require OurNet::BBS::ScalarFile;
        tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
            "$self->{bbsroot}/$PATH_BRD/$self->{board}/$key";

        return 1;
    }

    my $file = "$self->{bbsroot}/$BRD";
    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};
    $self->{mtime} = (stat($file))[9];

    local $/ = \$packsize;
    open(my $DIR, $file) or die "can't read $BRD: $!";

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_cache}{id} ne $self->{board}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;

        while (my $data = <$DIR>) {
            @{$self->{_cache}}{@packlist} = unpack($packstring, $data);
            last if ($self->{_cache}{id} eq $self->{board});
            $self->{recno}++;
        }

	no warnings 'uninitialized';

        if ($self->{_cache}{id} ne $self->{board}) {
            $self->{_cache}{id}       = $self->{board};
            $self->{_cache}{bm}       = '';
            $self->{_cache}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_cache}{title}    = '(untitled)';

            mkdir "$self->{bbsroot}/$PATH_BRD/$self->{board}";
            open $DIR, '>', "$self->{bbsroot}/$PATH_BRD/$self->{board}/.DIR";
            close $DIR;

            mkdir "$self->{bbsroot}/$PATH_GEM/$self->{board}";
            open $DIR, '>', "$self->{bbsroot}/$PATH_GEM/$self->{board}/.DIR";
            close $DIR;

            open $DIR, '>>', $file 
		or die "can't write $BRD file for $self->{board}: $!";

	    no warnings 'uninitialized';
            print $DIR pack($packstring, @{$self->{_cache}}{@packlist});

            close $DIR;
	    $self->post_new_board();
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return if (index(' '.join(' ', @packlist).' ', " $key ") == -1);

    my $file = "$self->{bbsroot}/$BRD";
    open DIR, "+<$file" or die "cannot open $file for writing";
    # print "seeeking to ".($packsize * $self->{recno});
    seek DIR, $packsize * $self->{recno}, 0;
    print DIR pack($packstring, @{$self->{_cache}}{@packlist});
    close DIR;
    $self->{mtime} = (stat($file))[9];
    $self->shmtouch() if exists $self->{shm};
}

sub shmtouch {
    my $self = shift;
    $self->{shm}{touchtime} = time();
}

sub remove {
    my $self = shift;
=emergercy fix
    my $file = "$self->{bbsroot}/.BOARDS";
    open DIR, "+<$file" or die "cannot open $file for writing";
    # print "seeeking to ".($packsize * $self->{recno});
    seek DIR, $packsize * $self->{recno}, 0;
    print DIR "\0" x $packsize;
    close DIR;
=cut

    OurNet::BBS::Utils::deltree("$self->{bbsroot}/$PATH_BRD/$self->{board}");
    OurNet::BBS::Utils::deltree("$self->{bbsroot}/$PATH_GEM/$self->{board}");

    return 1;
}

1;
