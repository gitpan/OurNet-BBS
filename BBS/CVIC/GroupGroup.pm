# $File: //depot/OurNet-BBS/BBS/CVIC/GroupGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1134 $ $DateTime: 2001/06/14 18:08:06 $

package OurNet::BBS::CVIC::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group";

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Group')->new(
            $self->{bbsroot}, $key
        );
        return;
    }

    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};
    $self->{mtime} = (stat($file))[9];

    opendir DIR, $file or die "can't read group file $file: $!";
    %{$self->{_cache}} = map {
        ($_, $self->module('Group')->new($self->{bbsroot}, $_));
    } grep {
        /^[^\.]/;
    } readdir(DIR);
    closedir DIR;
}

sub STORE {
    my ($self, $key) = @_;

    $self->{_cache}{$key}->refresh();
}

sub EXISTS {
    my ($self, $key) = @_;

    return ((-e "$self->{bbsroot}/group/$key") ? 1 : 0);
}

1;
