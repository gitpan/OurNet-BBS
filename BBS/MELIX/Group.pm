# $File: //depot/OurNet-BBS/BBS/MELIX/Group.pm $ $Author: autrijus $
# $Revision: #15 $ $Change: 1730 $ $DateTime: 2001/09/06 06:24:43 $

package OurNet::BBS::MELIX::Group;

use strict;
use fields qw/bbsroot parent recno group/,
           qw/time xmode xid id author nick date title mtime _ego _hash/;
use OurNet::BBS::Base (
    'GroupGroup' => [
	qw/$packstring $packsize @packlist &STORE &_refresh_meta/,
	qw/&GEM_FOLDER &GEM_BOARD &GEM_GOPHER &GEM_HTTP &GEM_EXTEND/,
    ],
    'Board'	   => [qw/&remove_entry/],
);

use constant IsWin32 => ($^O eq 'MSWin32');
use open (IsWin32 ? (IN => ':raw', OUT => ':raw') : ());

sub readok { 1 }
sub writeok { 0 }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $board;

    if (!$key or index(' owner title id ', " $key ") > -1) {
	@{$self->{_hash}}{qw/owner title id/} = @{$self}{qw/author title id/};
	return 1;
    }

    return $self->_refresh_meta;
}

sub remove {
    my $self = shift->ego;

    $self->remove_entry("$self->{bbsroot}/gem/\@/\@$self->{parent}");
    return unlink "$self->{bbsroot}/gem/\@/\@$self->{group}";
}

1;
