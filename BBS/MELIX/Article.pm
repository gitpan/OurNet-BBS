# $File: //depot/OurNet-BBS/BBS/MELIX/Article.pm $ $Author: autrijus $
# $Revision: #20 $ $Change: 1605 $ $DateTime: 2001/08/30 02:22:21 $

package OurNet::BBS::MELIX::Article;

use constant IsWin32 => ($^O eq 'MSWin32');
use open (IsWin32 ? (IN => ':raw', OUT => ':raw') : ());

use strict;
use base qw/OurNet::BBS::MAPLE3::Article/;
use fields qw/_ego _hash/;
use subs qw/writeok STORE _parse_body/;
use OurNet::BBS::Base;

sub writeok {
    my ($self, $user, $op) = @_;
    return if $op eq 'DELETE';

    # in melix, only sysop could modify an article
    return ($user->has_perm('PERM_SYSOP'));
}

sub _parse_body {
    my ($self, $file) = @_;

    local $/;
    open(my $DIR, $file) or die "can't open DIR file for $self->{board}";

    my ($head, $body) = split("\n\n", <$DIR>, 2);

    ($head, $body) = ('', $head) unless defined $body;

    $head =~ s/\n\s+/ /g; # merge continuation lines
    $self->{_hash}{header} = { $head =~ /^([\w-]+):[\s\t]*(.+)/mg };
    $self->{_hash}{body}   = $body;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;
    $self->refresh_meta($key);

    $self->{_hash}{header}{Date} ||= localtime($self->{_hash}{time})
	if $self->{_hash}{time};

    if ($key eq 'body') {
	my $file = "$self->{basepath}/$self->{board}/".
	    substr($self->{name}, -1).'/'.$self->{name};

        open(my $BODY, '>', $file) or die "cannot open $file: $!";

	my $hdr = $self->{_hash}{header};

	if (%{$hdr}) {
	    foreach my $head (qw/From Board Subject Date/) {
	        print $BODY "$head: $hdr->{$head}\n" if exists $hdr->{$head};
	    }
	
	    foreach my $head (keys(%{$hdr})) {
	        next if index(' From Board Subject Date', $head) > -1;
	        print $BODY "$head: $hdr->{$head}\n";
	    }
	
	    print $BODY "\n";
        }

        print $BODY $value;
        close $BODY;

        $self->{_hash}{$key} = $value;
	$self->filestamp($file, 'btime');
    }
    else {
	no warnings 'uninitialized';

        $self->{_hash}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

        open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_hash}}{@packlist});
        close $DIR;

	$self->filestamp($file);
    }
}

1;
