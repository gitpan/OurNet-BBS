# $File: //depot/OurNet-BBS/BBS/MAPLE3/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MAPLE3::ArticleGroup;

# hdrfile for the upper level hdr file holding metadata of this level
# idxfile for hdr of the deeper level that this articlegroup is holding.

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/basepath board name dir hdrfile idxfile recno 
	      bm readlevel postlevel mtime btime _cache _phash/;
use subs qw/readok writeok/;
use open IN => ':raw', OUT => ':raw';

use constant GEM_FOLDER  => 0x00010000;
use constant GEM_BOARD   => 0x00020000;
use constant GEM_GOPHER  => 0x00040000;
use constant GEM_HTTP    => 0x00080000;
use constant GEM_EXTEND  => 0x80000000;
use constant POST_DELETE => 0x0080;

my %chronos;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'LLLZ32Z80Z50Z9Z73',
        '$packsize'   => 256,
        '@packlist'   => [qw/time xmode xid id author nick date title/],
    );
}

sub writeok {
    my ($self, $user, $op, $argref) = @_;

    # store/delete an arbitary article require bm permission in that board
    return 1 if $user->has_perm('PERM_BM') or ($user->id() eq $self->bm());

    # but actually you can store your own article, no big deal
    if ($op eq 'STORE') {
	# check the author bit
	my $value = $argref->[0];
	my $id    = $user->id();

	return 1 if $value->{author} and $value->{author} ne $id;

	my $header = $value->{header} if $value->{header};

	return 1 if $header and substr(
	    $header->{From}, 0, length($id) + 1
	) eq "$id ";
    }

    return 0;
}

sub readok {
    my ($self, $user) = @_;

    my $readlevel = $self->readlevel();
    return (!$readlevel or $readlevel & $user->{userlevel});
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

sub refresh_id {
    my ($self, $key) = @_;

    my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";
    return if defined $self->{recno} and $self->timestamp($file, 'btime');

    local $/ = \$packsize;
    open(my $DIR, $file) or die "can't read DIR file $file: $!";

    if (defined $self->{recno} and defined $self->{name}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{name} and defined $self->{recno}) {
	no warnings 'uninitialized';

	if (defined $self->{name}) { # seek for name
	    $self->{recno} = 0;

	    while (my $data = <$DIR>) {
		@{$self->{_cache}}{@packlist} = unpack($packstring, $data);
		last if ($self->{_cache}{id} eq $self->{name});
		$self->{recno}++;
	    }
	}
	else { # append
	    seek $DIR, 0, 2;
	    $self->{name} = stamp($self->{_cache}{time} = $self->new_id);
	    $self->{idxfile} = substr($self->{name}, -1)."/$self->{name}";
	    $self->{recno} = (stat($DIR))[7] / $packsize; # filesize/packsize
	}

	my @localtime = localtime;

        if ($self->{_cache}{id} ne $self->{name}) {
            $self->{_cache}{id}		= $self->{name};
            $self->{_cache}{xmode}	= GEM_FOLDER;
            $self->{_cache}{date}     ||= sprintf(
		"%02d/%02d/%02d", substr($localtime[5], -2), 
		$localtime[4] + 1, $localtime[3]
	    );
            $self->{_cache}{filemode} = 0;

            open(my $DIR, '+>>', $file)
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close $DIR;

            open($DIR, '>', join(
		'/', $self->{basepath}, $self->{board}, 
		substr($self->{name}, -1), $self->{name}
	    )) or die "can't write BODY file for $self->{board}: $!";
            close $DIR;
        }
    }

    return 1;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

    no warnings 'uninitialized';

    my $file = "$self->{basepath}/$self->{board}/$self->{idxfile}";
    my $name;

    goto &refresh_id if ($key and $self->contains($key));
    $self->refresh_id if (!defined($key) and $self->{dir});

    if ($key and ($key =~ /\D/)) { # XXX arrayftech doesn't work?
	no warnings 'uninitialized';

        # hash key -- no recaching needed
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module(
	    substr($key, 0, 2) eq 'D.' ? 'ArticleGroup' : 'Article'
	)->new(
	    $self->{basepath},
	    $self->{board},
	    $key,
	    "$self->{dir}/$self->{name}",
	    '.DIR',
	);

        $self->{_phash}[0][0]{$key} = $obj->recno+1;
        $self->{_phash}[0][$obj->recno+1] = $obj;

        return 1;
    }

    open(my $DIR, $file) or (warn "can't read DIR file for $file: $!", return);

    if ($key) {
        # out-of-bound check
        die 'no such article' 
	    if $key < 1 || $key > int((stat($file))[7] / $packsize);

        my (%param, %entry);

        local $/ = \$packsize;

        seek $DIR, $packsize * ($key - 1), 0;
        @entry{@packlist} = unpack($packstring, <$DIR>);
        close $DIR;

	# XXX: better exception handling needed here!
	die "article deleted" if $entry{xmode} & POST_DELETE;
        $name = $entry{id};
        return if $self->{_phash}[0][0]{$name} == $key;

	no warnings 'uninitialized';
        $param{idxfile} = substr($entry{id},-1)."/$entry{id}"
            if $entry{xmode} & GEM_FOLDER;

        my $obj = $self->module(
	    ($entry{xmode} & GEM_FOLDER) ? 'ArticleGroup' : 'Article'
	)->new({
	    board	=> $self->{board},
	    basepath	=> $self->{basepath},
	    name	=> $name,
	    hdrfile	=> $self->{idxfile},
	    recno	=> $key - 1,
	    %param
	});

        $self->{_phash}[0][0]{$name} = $key;
        $self->{_phash}[0][$key] = $obj;

	$self->timestamp($file);

        return 1;
    }

    return if $self->timestamp($file);

    print "reloading articlegroup\n" if $OurNet::BBS::DEBUG;

    local $/ = \$packsize;
    seek $DIR, 0, 0;

    $self->{_phash}[0] = fields::phash(map {
	my (%param, %entry);

	@entry{@packlist} = unpack($packstring, <$DIR>);
	$name = $entry{id};

	# return the thing
	$param{idxfile} = substr($entry{id},-1)."/$entry{id}"
	    if $entry{xmode} & GEM_FOLDER;

	($name, $self->module(
	    ($entry{xmode} & GEM_FOLDER) ? 'ArticleGroup' : 'Article'
	)->new({
	    board	=> $self->{board},
	    basepath	=> $self->{basepath},
	    name	=> $name,
	    hdrfile	=> $self->{idxfile},
	    recno	=> $_,
	    %param,
	}));
    } (0..int((stat($file))[7] / $packsize)-1)); # size

    close $DIR;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';

    if ($self->contains($key)) {
        $self->refresh($key);
        $self->{_cache}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/.DIR";

	open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close $DIR;
    }
    else {
        my $obj;

        if ($key > 0 and exists $self->{_phash}[0][$key]) {
            $obj = $self->{_phash}[0][$key];
        }
        else {
            $obj = $self->module('Article', $value)->new({
		basepath	=> $self->{basepath},
		board		=> $self->{board},
		name		=> $self->{name},
		hdrfile		=> $self->{idxfile},
		recno		=> int($key) ? $key - 1 : undef,
	    });
        }

	$key = $obj->recno;
        while (my ($k, $v) = each %{$value}) {
            $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} || "\n";
        $self->refresh($key);
        $self->{mtime} = $obj->mtime;
    }

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});

    my $file = "$self->{basepath}/$self->{board}/$self->{name}/.DIR";
    return 0 if $self->{mtime} and (stat($file))[9] == $self->{mtime};

    open(my $DIR, $file) or die "can't read DIR file $file: $!";

    my $board;
    foreach (0..int((stat($file))[9] / $packsize)-1) {
        seek $DIR, $packsize * $_, 0;
        read $DIR, $board, 44;
        return 1 if unpack('x12Z32', $board) eq $key;
    }

    close $DIR;
    return 0;
}

1;
