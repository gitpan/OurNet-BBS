# $File: //depot/OurNet-BBS/BBS/MAPLE2/Article.pm $ $Author: autrijus $
# $Revision: #17 $ $Change: 1254 $ $DateTime: 2001/06/21 10:39:30 $

package OurNet::BBS::MAPLE2::Article;

use strict;
use warnings;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board basepath name dir recno mtime btime _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'ArticleGroup' => [qw/$packsize $packstring @packlist/]
    );
}

my %chronos;

sub basedir {
    my $self = shift;
    return join('/', $self->{bbsroot}, $self->{basepath},
                     $self->{board}, $self->{dir});
}

sub new_id {
    my $self = shift;
    my ($id, $file);

    $file = $self->basedir;

    unless (-e "$file/.DIR") {
        open(my $DIR, '>', "$file/.DIR") or die "cannot create $file/.DIR";
        close $DIR;
    }

    my $chrono = time;

    no warnings 'uninitialized';
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while ($id = "M.$chrono.A") {
        last unless -e "$file/$id";
        $chrono = ++$chronos{$self->{board}};
    }

    open(my $BODY, '>', "$file/$id") or die "cannot open $file/$id";
    close $BODY;

    return $id;
}

sub _refresh_body {
    my $self = shift;

    $self->{name} ||= $self->new_id;

    my $file = join('/', $self->basedir, $self->{name});

    return if $self->{btime} and (stat($file))[9] == $self->{btime}
                             and defined $self->{_cache}{body};

    $self->{btime} = (stat($file))[9];
    $self->{_cache}{date} ||= 
	sprintf("%2d/%02d", (localtime($self->{btime}))[4] + 1, 
	        (localtime($self->{btime}))[3]);

    local $/;
    open my $DIR, $file or die "can't open DIR file for $self->{board}";
    $self->{_cache}{body} = <$DIR>;
    close $DIR;

    my ($from, $title, $date);

    if ($self->{_cache}{body} =~ 
	s/^作者: ([^ \(]+)\s?(?:\((.+?)\) )?[^\n]*\n標題: (.*)\n時間: (.+)\n\n//
    ) {
        ($from, $self->{_cache}{nick}, $title, $date) = ($1, $2, $3, $4);
    }
    else {
        $self->refresh_meta;
    }

    $self->{_cache}{header} = {
        From	=> ($from || $self->{_cache}{author}) .
		   ($self->{_cache}{nick} ? " ($self->{_cache}{nick})" : ''),
        Subject	=> $title ||= $self->{_cache}{title},
        Date 	=> $date  ||= scalar localtime($self->{btime}),
	Board	=> $self->{board},
    };

    OurNet::BBS::Utils::set_msgid($self->{_cache}{header});

    return 1;
}

sub refresh_nick {
    shift->_refresh_body;
}

sub refresh_body {
    shift->_refresh_body;
}

sub refresh_header {
    shift->_refresh_body;
}

sub refresh_meta {
    my $self = shift;

    $self->{name} ||= $self->new_id();

    my $file = join('/', $self->basedir, $self->{name});
    return unless -e $file;
    $self->{btime} = (stat($file))[9];

    $file = join('/', $self->basedir, '.DIR');

    return if $self->timestamp($file);

    local $/ = \$packsize;
    open(my $DIR, $file) or die "can't read DIR file for $self->{board}: $!";

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <$DIR>);

        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;
        while (my $data = <$DIR>) {
            @{$self->{_cache}}{@packlist} = unpack($packstring, $data);
            # print "$self->{_cache}{id} versus $self->{name}\n";
            last if ($self->{_cache}{id} eq $self->{name});
            $self->{recno}++;
        }
        if ($self->{_cache}{id} ne $self->{name}) {
            $self->{_cache}{id} = $self->{name};
            $self->{_cache}{author}   ||= '(unknown).';
            $self->{_cache}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_cache}{title}    = 
		(substr($self->{basepath}, 0, 4) eq 'man/')
		    ? '◇ (untitled)' : '(untitled)';
            $self->{_cache}{filemode} = 0;
            open $DIR, "+>>$file" 
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close $DIR;
            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, $self->{name});
        unless (-s $file) {
            $value =
                "作者: $self->{_cache}{author} ".
                (defined $self->{_cache}{nick} 
                    ? "($self->{_cache}{nick}) " : " ").
                "看板: $self->{board} \n".
                "標題: ".substr($self->{_cache}{title}, 0, 60)."\n".
                "時間: ".($self->{_cache}{datetime} || scalar localtime).
                "\n\n".
                $value;
        }
        open(my $BODY, '>', $file) or die "cannot open $file";
        print $BODY $value;
        close $BODY;
        $self->{btime} = (stat($file))[9];
        $self->{_cache}{$key} = $value;
    }
    else {
        if ($key eq 'title' and
            substr($self->{basepath}, 0, 4) eq 'man/' and
            substr($value, 0, 3) ne '◇ ') {
            $value = "◇ $value";
        }

        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir, '.DIR');

        open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close $DIR;

	$self->timestamp($file);
    }
}

sub remove {
    my $self = shift;
    my $file = join('/', $self->basedir, '.DIR');

    open(my $DIR, $file) or die "cannot open $file for reading";
    # print "seeeking to ".($packsize * $self->{recno});

    my ($before, $after) = ('', '');

    if ($self->{recno}) {
        # before...
        seek $DIR, 0, 0;
        read($DIR, $before, $packsize * $self->{recno});
    }

    if ($self->{recno} < ((stat($file))[7] / $packsize) - 1) {
        seek $DIR, $packsize * ($self->{recno} + 1), 0;
        read(
	    $DIR, $after, 
	    $packsize * (
		(stat($file))[7] - (($self->{recno} + 1) * $packsize)
	    )
	);
    }

    close $DIR;

    open $DIR, '>', $file or die "cannot open $file for writing";
    print $DIR $before . $after;
    close $DIR;

    return unlink join('/', $self->basedir, $self->{name});
}

1;
