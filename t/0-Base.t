#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/0-Base.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package Derived;

use strict;
use fields qw/foo bar baz _ego _array _hash _code _glob/;
use OurNet::BBS::Base;

sub set {
    $_[0]->ego->{_glob} = $_[1];
    return GLOB;
}

sub power_of_2 {
    return 2 ** $_[1];
}

sub refresh_meta {
    my ($self, $key, $flag) = @_;

    if (!defined($flag)) {
	$self->{baz} = 'baaz';
    }
    elsif ($flag == ARRAY) {
	if (defined($key)) {
	    $self->{_array}[$key] = $self->power_of_2($key);
	}
	else {
	    $#{$self->{_array}} = 512;
	}
    }
    elsif ($flag == CODE) {
	$self->{_code} = sub { return $_[0] ** 2 };
    }
    elsif ($flag == HASH) {
	$self->{_hash}{$key} = $key;
    }
}

package main;

use strict;
use Test::More tests => 9;
use OurNet::BBS::Base;

my $pkg = 'Derived';
my $obj = $pkg->new(qw/goo gar gaz/);

is(ref($obj),		$pkg,	'constructor');
is($obj->baz,		'baaz',	'subroutine call');
is(ref($$obj),		'ARRAY','scalar deref');
is($obj->{baz},		'baz',	'hash deref');
is($obj->[10],		1024,	'array deref + ego function');
is($#{$obj},		512,	'array fetchsize');
is($obj->(10),		100,	'code deref');
is($obj->set(*STDIN),	GLOB,	'self function');
is(*{$obj},		*STDIN,	'glob deref');

__END__
