# $File: //depot/OurNet-BBS/BBS/MELIX/Article.pm $ $Author: autrijus $
# $Revision: #15 $ $Change: 1460 $ $DateTime: 2001/07/17 22:31:42 $

package OurNet::BBS::MELIX::Article;

use strict;
use base qw/OurNet::BBS::MAPLE3::Article/;
use fields qw/_cache/;
use subs qw/STORE readok writeok/;
use open IN => ':raw', OUT => ':raw';

BEGIN { __PACKAGE__->initvars() };

sub writeok {
    my ($self, $user, $op) = @_;

    return if $op eq 'DELETE';

    # in melix, only sysop could modify an article
    return ($user->has_perm('PERM_SYSOP'));
}

# well, since you're here...
sub readok { 1 }

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);

    if ($key eq 'body') {
	my $file = "$self->{basepath}/$self->{board}/".
	    substr($self->{name}, -1).'/'.$self->{name};

        open(my $BODY, '>', $file) or die "cannot open $file: $!";

        unless (-s $file) {
            my $hdr = $self->{_cache}{header};

	    if (%{$hdr}) {
		foreach my $head (qw/From Board Subject Date/) {
		    print $BODY "$head: $hdr->{$head}\n" 
			if exists $hdr->{$head};
		}

		foreach my $head (keys(%{$hdr})) {
		    next if index(' From Board Subject Date', $head) > -1;
		    print $BODY "$head: $hdr->{$head}\n";
		}

		print $BODY "\n";
	    }
        }

        print $BODY $value;
        close $BODY;

        $self->{_cache}{$key} = $value;
	$self->timestamp($file, 'btime');
    }
    else {
	no warnings 'uninitialized';

        $self->{_cache}{$key} = $value;

	my $file = "$self->{basepath}/$self->{board}/$self->{hdrfile}";

        open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close $DIR;

	$self->timestamp($file);
    }
}

1;
