package OurNet::BBS::MELIX::Session;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/recno shmid shm chatport registered _cache/;
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
    @{$self->{_cache}{pmsgs}} = unpack('S9', $self->{_cache}{msgs});
}

sub refresh_chat {
    my $self = shift;
    die 'no chat yet';
}

sub _shmwrite {
    my $self = shift;
    shmwrite($self->{shmid}, pack($packstring, @{$self->{_cache}}{@packlist}),
	     $packsize*$self->{recno}, $packsize);
}

sub dispatch {
    my ($self, $from, $message) = @_;

    $self->{_cache}{msgs} = pack('S9', 0);
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
    local $^W = 0; # turn off uninitialized warnings

    if ($key eq 'msg') {
	my $head = $self->{shm}{mbase};
	my ($sendername, $senderid);
	while ($self->{shm}{mpool}[$head][0] > time()-60) {
	    ++$head;
	}
	$self->{shm}{mbase} = $head;
	# qw/btime caller sender reciever userid message/}
	if (ref($value->[0])) {
	    $senderid = $value->[0]->{uid};
	    $sendername = $value->[0]->{userid};
	}
	else {
	    $sendername = $value->[0];
	}
	$self->{shm}{mpool}[$head] = [time(), 0, $senderid, $self->{_cache}{uid}, $sendername, $value->[1]];
	$self->{_cache}{msgs} =pack('S', $head+1);
	$self->_shmwrite();
	kill SIGUSR2, $self->{_cache}{pid};

	return;
    }
    elsif ($key eq 'cb_msg') {
	if (ref($value) eq 'CODE') {
	    print "register callback from $self->{registered}\n";
	    $self->{registered}{$self->{recno}} = $self;
	}
	else {
	    delete $self->{registered}{$self->{recno}};
	}
    }

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return if (index(' '.join(' ', @packlist).' ', " $key ") == -1);

    $self->_shmwrite();
}

sub DESTROY {
    my $self = shift;
    return unless $self->{_cache}{flag};
    $self->{_cache}{pid} = $self->{_cache}{uid} = 0;
    $self->_shmwrite();
    --$self->{shm}{number};
    delete $self->{registered}{$self->{recno}};
}
