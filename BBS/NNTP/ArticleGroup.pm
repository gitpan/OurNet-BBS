# $File: //depot/OurNet-BBS/BBS/NNTP/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1181 $ $DateTime: 2001/06/17 22:14:27 $

package OurNet::BBS::NNTP::ArticleGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/nntp board groupname first num last _cache _phash/;
use Date::Parse;
use Date::Format;

# FIXME: use first/last update to determine refresh result

BEGIN {
    __PACKAGE__->initvars(
        '@packlist'   => [qw//],
    );
}

sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

    no warnings; # XXX: why?

    # for compatibility.
    $self->{board} ||= $self->{groupname};
    @{$self}{qw/num first last/} = $self->{nntp}->group($self->{groupname})
	unless $self->{groupname} eq $self->{nntp}->group();

    if ($arrayfetch) {
        die "$key out of range"
	    if $key < $self->{first} || $key > $self->{last};

	my $head = $self->{nntp}->head($key);

	die "no such article $key" unless defined $head;

        return if $self->{_phash}[0][$key];

        my $obj = $self->module('Article')->new({
	    nntp	=> $self->{nntp},
	    groupname	=> $self->{groupname},
	    recno	=> $key
	});

        $self->{_phash}[0][0]{$key} = $key;
        $self->{_phash}[0][$key] = $obj;
    }
    elsif ($key) {
	die 'no key fetch yet';
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    die "STORE: attempt to store non-hash value ($value) into ".ref($self)
	unless UNIVERSAL::isa($value, 'HASH');

    @{$self}{qw/first num last/} = $self->{nntp}->group($self->{groupname})
	unless $self->{groupname} eq $self->{nntp}->group();

    my %header = %{$value->{header}};

    $header{Date} = time2str('%d %b %Y %T %Z', str2time($header{Date}));
    $header{Newsgroups} ||= $self->{groupname};
    $header{'Message-ID'} =~ s/^([^<].*[^>])$/<$1>/;
    delete $header{Board};

    $self->{nntp}->post(
	(sort { $a cmp $b } map {"$_: $header{$_}\n"} (keys %header)),
	"\n", 
	$value->{body},
    );
    print "post returns: ".$self->{nntp}->message if $OurNet::BBS::DEBUG;

    return 1;
}

sub EXISTS {
    my ($self, $key) = @_;

    return 1 if exists ($self->{_cache}{$key});
}

1;
