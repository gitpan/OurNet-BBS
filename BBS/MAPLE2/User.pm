# $File: //depot/OurNet-BBS/BBS/MAPLE2/User.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::MAPLE2::User;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot id recno _cache/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'Z13Z20Z24Z14CISSLLZ16Z8Z50Z50Z39',
        '$packsize'   => 256,
        '@packlist'   => [
	    qw/userid realname username passwd uflag userlevel numlogins 
	       numposts firstlogin lastlogin lasthost remoteuser email 
	       address justify month day year reserved state/
        ],
    );
}

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{_cache}{uid} ||= $self->{recno} - 1;
    $self->{_cache}{name} ||= $self->{id};
    return if exists $self->{_cache}{$key};

    if ($self->contains($key)) {
	my $buf = '';

	open(my $USR, "$self->{bbsroot}/.PASSWDS") or die "can't open .PASSWDS";
	seek $USR, $self->{recno} * $packsize, 0;
	read $USR, $buf, $packsize;
	close $USR;

	@{$self->{_cache}}{@packlist} = unpack($packstring, $buf);
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";
    }

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_cache}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        $self->{id},
        'home',
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($self->contains($key)) {
 	$self->refresh_meta($key);
	$self->{_cache}{$key} = $value;

	open(my $USR, '+<', "$self->{bbsroot}/.PASSWDS")
	    or die "can't open .PASSWDS";
	seek $USR, $self->{recno} * $packsize, 0;
        print $USR pack($packstring, @{$self->{_cache}}{@packlist});
	close $USR;
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";

	$self->{_cache}{$key} = $value;
    }

    return 1;
}

1;

