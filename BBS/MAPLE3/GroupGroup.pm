# $File: //depot/OurNet-BBS/BBS/MAPLE3/GroupGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::MAPLE3::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;

sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/gem/@/";

    if ($key) {
        $self->{_cache}{$key} = $self->module('Group')->new(
            $self->{bbsroot}, $key,
        );
        return;
    }

    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};
    $self->{mtime} = (stat($file))[9];

    opendir DIR, $file or die "can't read group file $file: $!";

    %{$self->{_cache}} = map {
        s/^\@//;
        ($_, $self->module('Group')->new($self->{bbsroot}, $_));
    } grep {
        my $st = "$self->{bbsroot}/gem/@/$_";
        /^\@/ and -e $st and (stat($st))[9] % 256 == 0;
    } readdir(DIR);

    closedir DIR;
}

1;
