# $File: //depot/OurNet-BBS/BBS/MELIX/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MELIX::ArticleGroup;

use strict;
use Date::Parse;
use Date::Format;

use base qw/OurNet::BBS::MAPLE3::ArticleGroup/;
use fields qw/_cache _phash/;
use subs qw/STORE/;
use open IN => ':raw', OUT => ':raw';

BEGIN { __PACKAGE__->initvars() };

sub STORE {
    my ($self, $key, $value) = @_;

    if ($self->contains($key)) {
	$self->refresh($key);
	$self->{_cache}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

	open(my $DIR, '+<', $file) or die "cannot open $file for writing";
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
	        basepath => $self->{basepath},
	        board    => $self->{board},
	        hdrfile  => $self->{idxfile},
	        recno    => int($key) ? $key - 1 : undef,
	    });
	}
	$key = $obj->recno;
	if (ref($obj) =~ m|ArticleGroup|) {
	    $obj->refresh('id');
	}
	elsif ($value->{header}) {
	    # modern style
	    no warnings 'uninitialized';

	    @{$value}{qw/author nick/} = ($1, $2)
		if $value->{header}{From} =~ m/(.+?)\s*(?:\((.*)\))/g;

	    $value->{date} = time2str(
		'%y/%m/%d', str2time($value->{header}{Date})
	    );
	    $value->{title} = $value->{header}{Subject};
	}
	else {
	    no warnings 'uninitialized';

	    # traditional style
	    $value->{header} = {
		From    => $value->{author}.
		(defined $self->{_cache}{nick} 
		    ? " ($self->{_cache}{nick})" : ''),
		Date    => scalar localtime,
		Subject => $value->{title},
		Board   => $self->board,
	    }
	}

	while (my ($k, $v) = each %{$value}) {
	    $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
	};

	$obj->{body} = $value->{body} if ($value->{body});
	$self->refresh($key);
	$self->{mtime} = $obj->{time}; # not mtime, due to chrono-ahead.
    }
}

1;
