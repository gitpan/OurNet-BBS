package OurNet::BBS::MAPLE3::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/basepath board name dir hdrfile recno mtime btime _cache/;
use subs qw/remove/;
use vars qw/%chronos/;
use POSIX;

BEGIN {
    __PACKAGE__->initvars(
        'ArticleGroup' => [qw/$packsize $packstring @packlist/],
    );
}

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

    $file = $self->basedir();

    unless (-e "$file/$self->{hdrfile}") {
        open _, ">$file/$self->{hdrfile}"
	    or die "cannot create $file/$self->{hdrfile}";
        close _;
    }

    $chrono = time();
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while (my $id = stamp($chrono)) {
        $fname = join('/', $file, substr($id, -1), $id);
        last unless -e $fname;
        $chrono = ++$chronos{$self->{board}};
    }

    open _, ">$fname" or die "cannot open $fname";
    close _;

    return $chrono;
}

sub _refresh_body {
    my $self = shift;

    unless ($self->{name}) {
        $self->{_cache}{time} = $self->new_id();
        $self->{name} = stamp($self->{_cache}{time});
    }

    my $file = join('/', $self->basedir, substr($self->{name}, -1), $self->{name});

    return if $self->{btime} and (stat($file))[9] == $self->{btime}
                             and defined $self->{_cache}{body};

    $self->{btime} = (stat($file))[9];
    $self->{_cache}{date} ||= sprintf("%02d/%2d/%02d", substr((localtime)[5]+1900, -2), (localtime($self->{btime}))[4] + 1, (localtime($self->{btime}))[3]);

    local $/;
    open _, $file or die "can't open DIR file for $self->{board}";
    $self->{_cache}{body} = <_>;

    my %x;
    my ($head, $body) = (index($self->{_cache}{body}, "\n\n") > -1)
        ? split("\n\n", $self->{_cache}{body}, 2)
        : ('', $self->{_cache}{body});

    foreach (split("\n", $head)) {
        $x{$1} = $2 if m/^([\w-]+): ([^\n]+)/ or return;# die "bad heaer";
    }

    $self->{_cache}{header} = \%x;
    $self->{_cache}{body} = $body;
    $self->{_cache}{header}{'Message-ID'} ||=
        OurNet::BBS::Utils::get_msgid(@{$self->{_cache}{header}}
                                      {qw/Date From Board/});
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

    my $file = join('/', $self->basedir, substr($self->{name}, -1), $self->{name});
    return unless -e $file;
    $self->{btime} = (stat($file))[9]; 

    $file = join('/', $self->basedir, $self->{hdrfile});
    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};
    $self->{mtime} = (stat($file))[9];

    local $/ = \$packsize;
    open DIR, "$file" or die "can't read DIR file for $self->{board}: $!";
    my $filesize = (stat($file))[7];

    if (defined $self->{recno}) {
        seek DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <DIR>);

        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek DIR, 0, 0;
        }
    }
    unless (defined $self->{recno}) {
        seek DIR, 0, SEEK_END;
        $self->{recno} = $filesize / $packsize;
        if ($self->{_cache}{id} ne $self->{name}) {
            $self->{_cache}{id} = $self->{name};
            $self->{_cache}{author}   ||= 'guest.';
            $self->{_cache}{nick}     ||= '�ѥ~�ӫ�';
            $self->{_cache}{date}     ||= sprintf("%02d/%02d/%02d", substr((localtime)[5]+1900, -2), (localtime)[4] + 1, (localtime)[3]);
            $self->{_cache}{title}    ||= '(untitled)';
            $self->{_cache}{filemode} = 0;

            open DIR, "+>>$file" or die "can't write DIR file for $self->{board}: $!";
            print DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close DIR;
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, substr($self->{name}, -1), $self->{name});
        unless (-s $file or substr($value, 0, 6) eq '�@��: ') {
            $value =
            "�@��: $self->{_cache}{author} ($self->{_cache}{nick}) ".
            "�ݪO: $self->{board} \n���D: ".substr($self->{_cache}{title}, 0, 60).
            "\n�ɶ�: ".($self->{_cache}{datetime} || scalar localtime)."\n\n".$value;
        }
        open _, ">$file" or die "cannot open $file";
        print _ $value;
        close _;
        $self->{btime} = (stat($file))[9];
        $self->{_cache}{$key} = $value;
    }
    else {
        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir, $self->{hdrfile});

        open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = (stat($file))[9];
    }
}

=comment
sub remove {
    die "don't remove please";
    my $self = shift;
    my $file = join('/', $self->basedir, $self->{hdrfile});

    open DIR, $file or die "cannot open $file for reading";
    # print "seeeking to ".($packsize * $self->{recno});

    my $buf = '';
    if ($self->{recno}) {
        # before...
        seek DIR, 0, 0;
        read(DIR, $buf, $packsize * $self->{recno});
    }
    if ($self->{recno} < ((stat($file))[7] / $packsize) - 1) {
        seek DIR, $packsize * ($self->{recno}+1), 0;
        read(DIR, $buf, $packsize * ((stat($file))[9] - (($self->{recno}+1) * $packsize)));
    }

    close DIR;

    open DIR, ">$file" or die "cannot open $file for writing";
    print DIR $buf;
    close DIR;

    return unlink join('/', $self->basedir, $self->{name});
}
=cut

1;

