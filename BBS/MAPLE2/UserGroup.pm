# $File: //depot/OurNet-BBS/BBS/MAPLE2/UserGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::MAPLE2::UserGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot shmkey maxuser shmid shm _cache _phash/;
use OurNet::BBS::ShmScalar;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

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
            tie $self->{_cache}{number}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13+8, 4, 'L';
            tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxuser}*13+12, 4, 'L';
        }
    }

    my $name;
    if ($key) {
        if (length($key) and $arrayfetch) {
            shmread($self->{shmid}, $name, 13 * $key, 13);
            $name = unpack('Z13', $name);
            return if $self->{_phash}[0][0]{$name} == $key;
        }
        elsif ($key) {
            # key fetch
            return if $self->{_phash}[0][0]{$key};

            my $buf;
            $name = $key;
            $key = '';

            foreach my $rec (1..$self->{maxuser}) {
                shmread($self->{shmid}, $buf, 13 * $rec, 13);
                # print "$buf\n";
                if ($name eq unpack('Z13', $buf)) {
                    $key = $rec;
                    last;
                }
            }
            $key ||= $self->{maxuser}++;
        }
    }

    print "new $name $key\n" if $OurNet::BBS::DEBUG;

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key, # XXX -1?
    );

    $self->{_phash}[0][0]{$name} = $key;
    $self->{_phash}[0][$key] = $obj;

    return 1;
}
1;

