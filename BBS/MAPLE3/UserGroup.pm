# $File: //depot/OurNet-BBS/BBS/MAPLE3/UserGroup.pm $ $Author: autrijus $
# $Revision: #18 $ $Change: 2992 $ $DateTime: 2002/02/04 12:27:50 $

package OurNet::BBS::MAPLE3::UserGroup;

use strict;
use fields qw/bbsroot _ego _hash _array/;
use subs qw/writeok readok/;

use OurNet::BBS::Base (
    '$packstring' => 'iZ13Z14CZ20Z24IiiILLLLZ32iLZ60Z60Z60Z60Z120L',
    '$packsize'   => 512,
    '@packlist'   => [ qw(
	userno userid passwd signature realname username userlevel 
	numlogins numposts ufo firstlogin lastlogin staytime tcheck 
	lasthost numemail tvalid email address justify vmail ident 
	vtime
    ) ],
);

use constant IsWin32 => ($^O eq 'MSWin32');
use open (IsWin32 ? (IN => ':raw', OUT => ':raw') : ());

sub writeok { 0 }
sub readok { 1 }

sub FETCHSIZE {
    my $self = $_[0]->ego;

    return (stat("$self->{bbsroot}/.USR"))[7] / 16;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;
    my $name;

    if (defined $key) {
        if ($flag == ARRAY) {
            # array fetch
            open my $DIR, "$self->{bbsroot}/.USR";
            seek $DIR, $key * 16 + 4, 0;
            read $DIR, $name, 12;
            $name = unpack('Z14', $name);
            close $DIR;
        }
        else {
            # key fetch
            $name = $key;
	   undef $key
        }

	return if $self->{_hash}{$name};
    }

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key,
    );

    $key = $obj->{userno} - 1 unless defined $key;

    $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    my $obj = $self->module('User', $value)->new($self->{bbsroot}, $key);

    while (my ($k, $v) = each %{$value}) {
        $obj->{$k} = $v unless $k eq 'id';
    };

    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return (exists ($self->{_hash}{$key}) or -d ("$self->{bbsroot}/usr/".lc(
	substr($key, 0, 1)
    )."/$key"));
}

1;
