package OurNet::BBS::MELIX::SessionGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE3::SessionGroup/;
use fields qw/_cache/;
use subs qw/shminit/;
use OurNet::BBS::ShmArray;
#my (%instances, %registered);

BEGIN {
  __PACKAGE__->initvars
    (
     '$packstring'    => 'LLLLLLLLa18Z13Z13Z24Z34x2',
     '$packsize'      => 136,
     '@packlist'   => 
     [
      qw/pid uid idle_time mode ufo sockaddr sockport destuip msgs userid
	 mateid username from/
     ],
    );
}

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
	$self->{shmid} = shmget($self->{shmkey},
				($self->{maxsession})*$packsize+36, 0)) {
      tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
	  $self->{shmid}, $self->{maxsession}*$packsize, 4, 'L';
      tie $self->{shm}{offset}, 'OurNet::BBS::ShmScalar',
	  $self->{shmid}, $self->{maxsession}*$packsize+4, 4, 'L';
      tie @{$self->{shm}{sysload}}, 'OurNet::BBS::ShmArray',
	  $self->{shmid}, $self->{maxsession}*$packsize+8, 8, 3, 'd';
      tie $self->{shm}{avgload}, 'OurNet::BBS::ShmScalar',
	  $self->{shmid}, $self->{maxsession}*$packsize+32, 4, 'L';
      tie $self->{shm}{mbase}, 'OurNet::BBS::ShmScalar',
	  $self->{shmid}, $self->{maxsession}*$packsize+36, 4, 'L';
      tie @{$self->{shm}{mpool}}, 'OurNet::BBS::ShmArray',
	  $self->{shmid}, $self->{maxsession}*$packsize+40, 100, 128, 'LLLLZ13Z71';
      $instances{$self} = $self;
    }
}


sub message_handler {
    # we don't handle multiple messages in the queue yet.
    foreach my $instance (values %instances) {
	print "checking $instance $instance->{shm}{offset}\n";
        $instance->refresh_meta($_)
            foreach (0..$instance->{shm}{offset}/$packsize);

        foreach my $session (values %{$registered{$instance}}) {
            $session->refresh_meta();
            if (my $which = $session->{_cache}{pmsgs}[0]) {
		my %msg;
		@msg{qw/btime caller sender reciever userid message/} =
		    @{$instance->{shm}{mpool}[$which-1]};
                my $from = $msg{sender} && (grep {$_->{pid} && $_->{uid} == $msg{sender}}
                    @{$instance->{_cache}}{0..$instance->{shm}{offset}/$packsize})[0];

                $session->dispatch($from, $msg{message});
            }
        }
    }
    $SIG{USR2} = \&message_handler;
};

$SIG{USR2} = \&message_handler;

sub STORE {
    my ($self, $key, $value) = @_;
    die "STORE: attempt to store non-hash value ($value) into ".ref($self)
        unless UNIVERSAL::isa($value, 'HASH');

    unless (length($key)) {
        undef $key;
        for my $newkey (0..$self->{maxsession}-1) {
            $self->refresh_meta($newkey);
print "slot $newkey pid = $self->{_cache}{$newkey}{pid}";
            ($key ||= $newkey, last) unless $self->{_cache}{$newkey}{pid};
        }
        print "new session slot $key...$self->{shm}{offset}\n";
	$self->{shm}{offset} += $packsize if $key*$packsize >= $self->{shm}{offset};
        print "new offset...$self->{shm}{offset}\n";
    }

    die "no more session $key" unless defined $key;

    $self->refresh_meta($key);
    %{$self->{_cache}{$key}} = %{$value};
    $self->{_cache}{$key}{flag} = 1;
    ++$self->{shm}{number};
}

sub DESTROY {
    my $self = shift;

    delete $instances{$self};
}

1;
