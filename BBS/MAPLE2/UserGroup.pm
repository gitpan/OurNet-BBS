# $File: //depot/OurNet-BBS/BBS/MAPLE2/UserGroup.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 1629 $ $DateTime: 2001/08/31 04:12:03 $

package OurNet::BBS::MAPLE2::UserGroup;

use strict;
use fields qw/bbsroot shmkey maxuser shmid shm _ego _hash _array/;
use OurNet::BBS::Base;
use OurNet::BBS::ShmScalar;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;

    unless ($self->{shmid} || !$self->{shmkey}) {
        if ($^O ne 'MSWin32' and
            $self->{shmid} = shmget($self->{shmkey},
				    ($self->{maxuser})*13+16, 0)) {
            # print "key: $self->{shmkey}\n";
            # print "maxuser: $self->{maxuser}\n";
            tie $self->{shm}{userlist}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, 0, 13, $self->{maxuser}*13, 'Z13';
            tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13, 4, 'L';
            tie $self->{shm}{touchtime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13+4, 4, 'L';
            tie $self->{_hash}{number}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13+8, 4, 'L';
            tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13+12, 4, 'L';
        }
    }

    my $name;
    if ($key) {
        if (length($key) and $flag == ARRAY) {
            shmread($self->{shmid}, $name, 13 * $key, 13);
            $name = unpack('Z13', $name);
            return if $self->{_hash}{$name} == $self->{_array}[$key];
        }
        elsif ($key) {
            # key fetch
            return if $self->{_hash}{$key} or !$self->{maxuser};

            my $buf;
            $name = $key;
            undef $key;

            foreach my $rec (1..$self->{maxuser}) {
                shmread($self->{shmid}, $buf, 13 * $rec, 13);
                if ($name eq unpack('Z13', $buf)) {
                    $key = $rec;
                    last;
                }
            }
            $key ||= $self->{maxuser} + 1;
        }
    }

    print "new $name $key\n" if $OurNet::BBS::DEBUG;

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key,
    );

    $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

    return 1;

}

1;
