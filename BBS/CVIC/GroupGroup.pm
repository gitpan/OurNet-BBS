# $File: //depot/OurNet-BBS/BBS/CVIC/GroupGroup.pm $ $Author: autrijus $
# $Revision: #12 $ $Change: 1732 $ $DateTime: 2001/09/06 07:13:05 $

package OurNet::BBS::CVIC::GroupGroup;

use strict;
use fields qw/bbsroot bbsego mtime _ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

sub _brdobj {
    my $brd = $_[0]{bbsego}{boards}{$_[1]};
    return $brd || {};
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group";

    return $self->{_hash}{$key} ||= $self->module('Group')->new(
	@{$self}{qw/bbsroot bbsego/}, $self->_brdobj($key), $key,
    ) if defined $key;

    return if $self->filestamp($file);

    opendir my $DIR, $file or die "can't read group file $file: $!";
    %{$self->{_hash}} = map {
        ($_, $self->module('Group')->new(
	    @{$self}{qw/bbsroot bbsego/}, $self->_brdobj($_), $_)
	);
    } grep {
        /^[^\.]/;
    } readdir($DIR);
    closedir $DIR;
}

sub STORE {
    my ($self, $key) = @_;
    $self = $self->ego;

    my $file = "$self->{bbsroot}/group/$key";
    open(my $TOUCH, '>', $file) unless -e $file;

    $self->refresh_meta($key);
    $self->{_hash}{$key}->refresh;
}

sub EXISTS {
    my ($self, $key) = @_;

    return ((-e $self->ego->{bbsroot}."/group/$key") ? 1 : 0);
}

1;
