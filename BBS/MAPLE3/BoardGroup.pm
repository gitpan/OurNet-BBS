package OurNet::BBS::MAPLE3::BoardGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_cache/;
use subs qw/shminit EXISTS readok writeok/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'Z13Z49Z37CLLLLLLL',
        '$packsize'   => 128,
        '@packlist'   => [
            qw/id title bm bvote bstamp readlevel postlevel
               battr btime bpost blast/
        ],
        '$BRD'        => '.BRD',
	'$PATH_BRD'   => 'brd',
	'$PATH_GEM'   => 'gem/brd',
    );
}

sub writeok {
    my ($self, $user) = @_;

    return $user->has_perm('PERM_BOARD');
}

sub readok {
    my ($self, $user, $op, $argref) = @_;

    # reading a board requires checking against its 'read' permission
    # XXX: must incoporate with board's permission here
    my $readlevel = $self->{$argref->[0]}{readlevel};
    return (!$readlevel or $readlevel & $user->{userlevel});
}

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
        $self->{shmid} = shmget($self->{shmkey}, $self->{maxboard}*$packsize+8, 0)) {
        tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
           $self->{shmid}, $self->{maxboard}*128, 4, 'L';
        tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*128+4, 4, 'L';
    }

    print "shmid = $self->{shmid} number: $self->{shm}{number}\n"
	if $OurNet::BBS::DEBUG;
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});
    return ((-d "$self->{bbsroot}/$PATH_BRD/$key") ? 1 : 0);
}

1;
