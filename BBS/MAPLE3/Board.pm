package OurNet::BBS::MAPLE3::Board;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_cache/;
use subs qw/post_new_board refresh_articles refresh_archives 
            shmtouch readok writeok/;

BEGIN { __PACKAGE__->initvars() };

sub writeok { 0 }

sub readok {
    my ($self, $user, $op) = @_;

    my $readlevel = $self->{readlevel};

    return ((!$readlevel or $readlevel & $user->{userlevel})
         or ($user->id() eq $self->bm())
	 or $user->has_perm('PERM_SYSOP'));
}

sub post_new_board {
    my $self = shift;
    foreach my $dir (
        "$self->{bbsroot}/$PATH_BRD/$self->{board}/",
        "$self->{bbsroot}/$PATH_GEM/$self->{board}/",
    ) {
        mkdir $dir;

        foreach my $subdir (0..9, 'A'..'V', '@') {
            mkdir "$dir$subdir";
        }
    }
}

sub refresh_articles {
    my $self = shift;

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new({
	basepath	=> "$self->{bbsroot}/$PATH_BRD",
	board		=> $self->{board},
	idxfile	 	=> '.DIR',
	bm		=> $self->{_cache}{bm},
	readlevel	=> $self->{_cache}{readlevel},
	postlevel	=> $self->{_cache}{postlevel},
    });
}

sub shmtouch {
    my $self = $_[0]->ego();
    $self->{shm}{uptime} = 0;
}

sub refresh_archives {
    my $self = shift;

    return $self->{_cache}{archives} ||= $self->module('ArticleGroup')->new({
	basepath	=> "$self->{bbsroot}/$PATH_GEM",
	board		=> $self->{board},
	idxfile		=> '.DIR',
	bm		=> $self->{_cache}{bm},
	readlevel	=> $self->{_cache}{readlevel} || 0xffffffff,
	postlevel	=> $self->{_cache}{postlevel} || 0xffffffff,
    });
}

1;
