package OurNet::BBS::MAPLE3::Board;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_cache/;
use subs qw/post_new_board refresh_articles refresh_archives shmtouch/;

BEGIN { __PACKAGE__->initvars() };

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

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new
      ({
	basepath => "$self->{bbsroot}/$PATH_BRD",
	board => $self->{board},
	idxfile => '.DIR',
       });
}

sub shmtouch {
    my $self = $_[0]->ego();
    $self->{shm}{uptime} = 0;
}

sub refresh_archives {
    my $self = shift;

    return $self->{_cache}{archives} ||= $self->module('ArticleGroup')->new
      ({
	basepath => "$self->{bbsroot}/$PATH_GEM",
	board => $self->{board},
	idxfile => '.DIR',
       });
}

1;
