# $File: //depot/OurNet-BBS/BBS/MAPLE3/Article.pm $ $Author: autrijus $
# $Revision: #14 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::MAPLE3::Article;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/basepath board name dir hdrfile recno mtime btime _cache/;
use subs qw/writeok readok remove/;

BEGIN {
    __PACKAGE__->initvars(
        'ArticleGroup' => [qw/$packsize $packstring @packlist/],
    );
}

my %chronos;

sub writeok {
    my ($self, $user, $op) = @_;

    return if $op eq 'DELETE';

    # STORE
    return ($self->{author} eq $user->id() 
	    or $user->has_perm('PERM_SYSOP'));
}

sub readok { 1 }

sub basedir {
    my $self = shift;
    return join('/', $self->{basepath}, $self->{board});
}

sub stamp {
    my $chrono = shift;
    my $str = '';
    for (1..7) {
        $str = ((0..9,'A'..'V')[$chrono & 31]) . $str;
        $chrono >>= 5;
    }
    return 'A'.$str;
}

sub new_id {
    my $self = shift;
    my ($chrono, $file, $fname);

    $file = "$self->{basepath}/$self->{board}";

    unless (-e "$file/$self->{hdrfile}") {
        open(my $HEADER, '>', "$file/$self->{hdrfile}")
	    or die "cannot create $file/$self->{hdrfile}";
        close $HEADER;
    }

    no warnings 'uninitialized';
    $chrono = time();
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while (my $id = stamp($chrono)) {
        $fname = join('/', $file, substr($id, -1), $id);
        last unless -e $fname;
        $chrono = ++$chronos{$self->{board}};
    }

    open(my $BODY, '>', $fname) or die "cannot open $fname";
    close $BODY;

    return $chrono;
}

sub _refresh_body {
    my $self = shift;

    $self->refresh_meta unless ($self->{name});

    my $file = "$self->{basepath}/$self->{board}/".
	substr($self->{name}, -1).'/'.$self->{name};

    die "no such file: $file" unless -e $file;

    return if $self->{btime} and (stat($file))[9] == $self->{btime}
                             and defined $self->{_cache}{body};

    $self->{btime} = (stat($file))[9];
    $self->{_cache}{date} ||= sprintf(
	"%02d/%2d/%02d", 
	substr((localtime)[5], -2), 
	(localtime($self->{btime}))[4] + 1,
	(localtime($self->{btime}))[3],
    );

    local $/;
    open(my $DIR, $file) or die "can't open DIR file for $self->{board}";

    my ($head, $body) = split("\n\n", <$DIR>, 2);

    ($head, $body) = ('', $head) unless defined $body;

    $self->{_cache}{header} = { $head =~ m/^([\w-]+):[\s\t]*(.*)/mg };
    $self->{_cache}{body}   = $body;

    OurNet::BBS::Utils::set_msgid(
	$self->{_cache}{header}
    ) unless $self->{_cache}{header}{'Message-ID'};

    return 1;
}

sub refresh_body {
    shift->_refresh_body;
}

sub refresh_header {
    shift->_refresh_body;
}

sub refresh_meta {
    my $self = shift;

    unless ($self->{name}) {
        $self->{_cache}{time} = $self->new_id();
        $self->{name} = stamp($self->{_cache}{time});
    }
 
    my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";
    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};

    my $filesize;
    local $/ = \$packsize;
    open(my $DIR, $file) or die "can't read DIR file for $self->{board}: $!";
    ($filesize, $self->{mtime}) = (stat($DIR))[7, 9];

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <$DIR>);

        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        seek $DIR, 0, 2;
        $self->{recno} = $filesize / $packsize;

	no warnings 'uninitialized';
	my @localtime = localtime;

        if ($self->{_cache}{id} ne $self->{name}) {
            $self->{_cache}{id} = $self->{name};
            $self->{_cache}{author}   ||= '(nobody).';
            $self->{_cache}{date}     ||= sprintf(
		"%02d/%02d/%02d", substr($localtime[5], -2), 
		$localtime[4] + 1, $localtime[3]
	    );
            $self->{_cache}{title}    = ' '
		unless defined $self->{_cache}{title};
            $self->{_cache}{filemode} = 0;

            open(my $DIR, '+>>', $file)
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close $DIR;
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->refresh_meta($key);

    if ($key eq 'body') {
	my $file = "$self->{basepath}/$self->{board}/".
	    substr($self->{name}, -1).'/'.$self->{name};

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
        $self->{_cache}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

        open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close $DIR;
        $self->{mtime} = (stat($file))[9];
    }
}

=comment out
sub remove {
    my $self = shift;
    my $file = join('/', $self->basedir, $self->{hdrfile});

    open(my $DIR, $file) or die "cannot open $file for reading";

    my ($before, $after) = ('', '');

    if ($self->{recno}) {
        # before...
        seek $DIR, 0, 0;
        read($DIR, $before, $packsize * $self->{recno});
    }

    if ($self->{recno} < ((stat($file))[7] / $packsize) - 1) {
	# after...
        seek $DIR, $packsize * ($self->{recno}+1), 0;
        read(
	    $DIR, $after,
	    $packsize * (
		(stat($file))[7] - (($self->{recno} + 1) * $packsize)
	    ),
	);
    }

    close $DIR;

    open($DIR, '>, $file) or die "cannot open $file for writing";
    print $DIR $before . $after;
    close $DIR;

    unlink join('/', $self->basedir, $self->{name});

    return 1;
}
=cut

1;

