# $File: //depot/OurNet-BBS/BBS/MAPLE3/Group.pm $ $Author: autrijus $ # $Revision: #9 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MAPLE3::Group;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot group/,
           qw/time xmode xid id author nick date title mtime _cache/;
use subs qw/readok/;
use open IN => ':raw', OUT => ':raw';

use constant GEM_FOLDER		=> 0x00010000;
use constant GEM_BOARD		=> 0x00020000;
use constant GEM_GOPHER		=> 0x00040000;
use constant GEM_HTTP		=> 0x00080000;
use constant GEM_EXTEND		=> 0x80000000;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'LLLZ32Z80Z50Z9Z73',
        '$packsize'   => 256,
        '@packlist'   => [qw/time xmode xid id author nick date title/],
    );
}

sub readok { 1 }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/gem/\@/\@$self->{group}";
    my $board;

    return unless $self->{group};
    return if $self->timestamp($file);

    my $GROUP;
    open($GROUP, $file) or open ($GROUP, '+>>', $file)
        or die("Cannot read group file $file: $!");

    return if (stat($file))[7] % $packsize;

    local $/ = \$packsize;

    my (%entry, $buf);

    while (defined($buf = <$GROUP>)) {
	@entry{@packlist} = unpack($packstring, $buf);

	$entry{id} =~ s/^@//;

	if ($entry{xmode} & GEM_BOARD) {
            $self->{_cache}{$entry{id}} = $self->module('Board')->new(
                $self->{bbsroot}, $entry{id}
            );
	}
	elsif ($entry{xmode} & GEM_FOLDER) {
            $self->{_cache}{$entry{id}} = $self->module('Group')->new(
                $self->{bbsroot}, $entry{id}, @entry{@packlist},
	    );
	}
    }
    close $GROUP;
}

sub STORE {
    my ($self, $key, $value) = @_;

    # heuristic:
    # - blessed refs are of their own type. 
    # - unblessed hashrefs are groups waiting to be built.
    #  = allows using ->{group} or the key for automatic creations.
    # - non-refs calls for auto-deduction; try board first.

    if (!ref($value)) {
	# deduction time
	$key = (-e "$self->{bbsroot}/brd/$key/.DIR")
		? $self->module('Board')->new($self->{bbsroot}, $key)
	     : (-e "$self->{bbsroot}/gem/\@/\@$key")
		? $self->module('Group')->new($self->{bbsroot}, $key)
	     : die "doesn't exists such group or board $key: panic!";
    }
    elsif (ref($value) eq 'HASH') {
	# create a new group here. yes. here.
	$key ||= $value->{id}; $value->{id} ||= $key;

	my $file = "$self->{bbsroot}/gem/\@/\@$key";
	unless (-e $file) {
	    open(my $DIR, '>', $file) or die "cannot open $file for writing";
	    close $DIR;
	}
    }

    return if exists $self->{_cache}{$key}; # doesn't make sense yet

    my $file = "$self->{bbsroot}/gem/\@/\@$self->{group}";

    die "doesn't exists such group or board $key: panic!"
        unless (-e "$self->{bbsroot}/gem/\@/\@$key" or
                -e "$self->{bbsroot}/brd/$key/.DIR");

    my %entry = (
	xmode	=> ref($value) =~ /Board/ ? GEM_BOARD : GEM_FOLDER,
	'time'	=> scalar time,
    );

    if ($entry{xmode} eq GEM_BOARD) {
	$entry{author} = $value->{bm};
	$entry{title}  = $value->{title};
	$entry{id}     = $value->{name};
    }
    elsif (ref($value) eq 'HASH') {
	# XXX: obscure API
	$entry{author} = $value->{author};
	$entry{title}  = $value->{title};
	$entry{id}     = $value->{id};
    }
    else {
	# XXX: obscure API
	$entry{author} = $value->author;
	$entry{title}  = $value->title;
	$entry{id}     = $value->group;
    }

    open(my $DIR, '+>>', $file)
	or die "can't write DIR file for $self->{group}: $!";
    print $DIR pack($packstring, @entry{@packlist});
    close $DIR;

    $self->{_cache}{$key} = $value;
}

sub remove {
    my $self = shift;
    return unlink "$self->{bbsroot}/gem/\@/\@$self->{group}";
}

1;
