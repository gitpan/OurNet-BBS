# $File: //depot/OurNet-BBS/BBS/CVIC/GroupGroup.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1267 $ $DateTime: 2001/06/23 20:35:33 $

package OurNet::BBS::CVIC::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;

BEGIN { __PACKAGE__->initvars() }

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

    return if $self->timestamp($file);

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
