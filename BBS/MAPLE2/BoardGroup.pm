package OurNet::BBS::MAPLE2::BoardGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot shmkey maxboard shmid shm mtime _cache/;
use OurNet::BBS::ShmScalar;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring'    => 'Z13Z49Z39Z11LZ3CLL',
        '$packsize'      => 128,
        '@packlist'      => [
	    qw/id title bm pad bupdate pad2 bvote vtime level/
	],
        '$BRD'           => '.BOARDS',
	'$PATH_BRD'      => 'boards',
	'$PATH_GEM'      => 'man/boards',

    );
}

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
        $self->{_cache}{$key} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $key,
            shmid   => $self->{bbsroot},
            shm     => $self->{shm},
        });

	print $self->{_cache}{$key}->shmid
	    if $OurNet::BBS::DEBUG;
        return;
    }

    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};

    $self->{mtime} = (stat($file))[9];

    open DIR, "$file" or die "can't read DIR file $file $!";

    foreach (0..int((stat($file))[7] / 128)-1) {
        seek DIR, 128 * $_, 0;
        read DIR, $board, 13;
        $board = unpack('Z13', $board);
        next unless $board and substr($board,0,1) ne "\0";

        $self->{_cache}{$board} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $board,
            shmid   => $self->{shmid},
            shm     => $self->{shm},
            recno   => $_,
        });
    }

    close DIR;
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});

    my $file = "$self->{bbsroot}/$BRD";
    return 0 if $self->{mtime} and (stat($file))[9] == $self->{mtime};

    open DIR, $file or die "can't read DIR file $file: $!";

    my $board;
    foreach (0..int((stat($file))[7] / 128)-1) {
        seek DIR, 128 * $_, 0;
        read DIR, $board, 13;
        return 1 if unpack('Z13', $board) eq $key;
    }

    close DIR;
    return 0;
}

sub STORE {
    my $self = shift;
    my $key  = shift;

    die "Need key for STORE" unless $key;

    foreach my $value (@_) {
        die "STORE: attempt to store non-hash value ($value) into ".ref($self)
            unless UNIVERSAL::isa($value, 'HASH');

        my $class  = (UNIVERSAL::isa($value, "UNIVERSAL"))
            ? ref($value) : $self->module('Board');
        my $module = "$class.pm";

        $module =~ s|::|/|g;
        require $module;

	$self->shminit unless ($self->{shmid} || !$self->{shmkey});

        %{$class->new({
            bbsroot => $self->{bbsroot},
            board   => $key,
            shmid   => $self->{shmid},
            shm     => $self->{shm},
        })} = (%{$value}, bstamp => time());
    }
}

1;
