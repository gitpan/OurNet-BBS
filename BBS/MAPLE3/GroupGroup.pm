# $File: //depot/OurNet-BBS/BBS/MAPLE3/GroupGroup.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MAPLE3::GroupGroup;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;
use subs qw/readok/;
use open IN => ':raw', OUT => ':raw';

BEGIN { __PACKAGE__->initvars() }

sub readok { 1 }

sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/gem/@/";

    if ($key) {
        $self->{_cache}{$key} = $self->module('Group')->new(
            $self->{bbsroot}, $key,
        );
        return;
    }

    return if $self->timestamp($file);

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
