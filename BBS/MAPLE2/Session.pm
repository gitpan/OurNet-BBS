# $File: //depot/OurNet-BBS/BBS/MAPLE2/Session.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1254 $ $DateTime: 2001/06/21 10:39:30 $

package OurNet::BBS::MAPLE2::Session;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot recno shmid shm chatport registered myshm _cache/;
use POSIX;

BEGIN {
    __PACKAGE__->initvars(
        'SessionGroup' => [qw/$packsize $packstring @packlist/],
    );
}

sub refresh_meta {
    my ($self, $key) = @_;

    my $buf;
    shmread($self->{shmid}, $buf, $packsize*$self->{recno}, $packsize)
        or die "shmread: $!";
    @{$self->{_cache}}{@packlist} = unpack($packstring, $buf);
}

sub refresh_chat {
    my $self = shift;
    return if exists $self->{_cache}{chat};

    require OurNet::BBS::SocketScalar;
    $self->refresh_meta('userid');

    tie $self->{_cache}{chat}, 'OurNet::BBS::SocketScalar',
        (index($self->{chatport}, ':') > -1) ? $self->{chatport}
             : ('localhost', $self->{chatport});

    $self->{_cache}{chat} = "/! 9 9 $self->{_cache}{userid} ".
                                   "$self->{_cache}{userid}\n";
    $self->{_cache}{chatid} = $self->{_cache}{userid};

    $self->_shmwrite();
}

sub _shmwrite {
    my $self = shift;
    shmwrite($self->{shmid}, pack($packstring, @{$self->{_cache}}{@packlist}),
	     $packsize*$self->{recno}, $packsize);
}

sub dispatch {
    my ($self, $from, $message) = @_;

    --$self->{_cache}{msgcount};
    $self->_shmwrite();

    $self->{_cache}{cb_msg} ($from, $message) if $self->{_cache}{cb_msg};
}

sub remove {
    my $self = shift;
    $self->{_cache}{pid} = 0;
    $self->_shmwrite();
    --$self->{shm}{number};
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';
    print "setting $key $value\n" if $OurNet::BBS::DEBUG;

    if ($key eq 'msg') {
	$self->{_cache}{msgs} =
	    pack('LZ13Z80', getpid(), $value->[0], $value->[1]);
	$self->{_cache}{msgcount}++;
	kill SIGUSR2, $self->{_cache}{pid};
	$self->_shmwrite();

	return;
    }
    elsif ($key eq 'cb_msg') {
	if (ref($value) eq 'CODE') {
	    print "register callback from $self->{registered}\n"
		if $OurNet::BBS::DEBUG;
	    $self->{registered}{$self->{recno}} = $self;
	}
	else {
	    delete $self->{registered}{$self->{recno}};
	}
    }

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return unless $self->contains($key);
    $self->_shmwrite();
}

sub DESTROY {
    my $self = shift;
    return unless exists $self->{registered}{$self->{recno}};
    $self->{_cache}{pid} = 0;
    $self->_shmwrite();
    delete $self->{registered}{$self->{recno}};
}

1;
