# $File: //depot/OurNet-BBS/BBS/MAPLE2/BoardGroup.pm $ $Author: autrijus $
# $Revision: #11 $ $Change: 1623 $ $DateTime: 2001/08/31 03:00:50 $

package OurNet::BBS::MAPLE2::BoardGroup;

use strict;
use fields qw/bbsroot shmkey maxboard shmid shm mtime _ego _hash/;
use OurNet::BBS::ShmScalar;

use OurNet::BBS::Base (
    '$packstring'    => 'Z13Z49Z39Z11LZ3CLL',
    '$packsize'      => 128,
    '@packlist'      => [
        qw/id title bm pad bupdate pad2 bvote vtime level/
    ],
    '$BRD'           => '.BOARDS',
    '$PATH_BRD'      => 'boards',
    '$PATH_GEM'      => 'man/boards',

);

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
        $self->{shmid} = shmget($self->{shmkey}, $self->{maxboard}*128+16, 0)) {
        tie $self->{shm}{touchtime}, 'OurNet::BBS::ShmScalar',
           $self->{shmid}, $self->{maxboard}*128+4, 4, 'L';
        tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*128+8, 4, 'L';
        tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*128+12, 4, 'L';
    }
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    my $file = "$self->{bbsroot}/$BRD";
    my $board;

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});

    if ($key) {
        $self->{_hash}{$key} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $key,
            shmid   => $self->{bbsroot},
            shm     => $self->{shm},
        });

	print $self->{_hash}{$key}->shmid if $OurNet::BBS::DEBUG;
        return;
    }

    return if $self->filestamp($file);

    open(my $DIR, $file) or die "can't read DIR file $file $!";

    foreach (0..int((stat($file))[7] / 128)-1) {
        seek $DIR, 128 * $_, 0;
        read $DIR, $board, 13;
        $board = unpack('Z13', $board);
        next unless $board and substr($board,0,1) ne "\0";

        $self->{_hash}{$board} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $board,
            shmid   => $self->{shmid},
            shm     => $self->{shm},
            recno   => $_,
        });
    }

    close $DIR;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;
    return 1 if exists ($self->{_hash}{$key});

    my $file = "$self->{bbsroot}/$BRD";
    return 0 if $self->filestamp($file, 'mtime', 1);

    open(my $DIR, $file) or die "can't read DIR file $file: $!";

    my $board;
    foreach (0 .. int((stat($file))[7] / 128)-1) {
        seek $DIR, 128 * $_, 0;
        read $DIR, $board, 13;
        return 1 if unpack('Z13', $board) eq $key;
    }

    close $DIR;
    return 0;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    die "Need key for STORE" unless $key;

    %{$self->module('Board', $value)->new({
	bbsroot => $self->{bbsroot},
	board   => $key,
	shmid   => $self->{shmid},
	shm     => $self->{shm},
    })} = (%{$value}, bstamp => CORE::time);

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});

    return 1;
}

1;
