# $File: //depot/OurNet-BBS/BBS/MAPLE2/User.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::MAPLE2::User;

use strict;
use fields qw/bbsroot id recno _ego _hash/;

use OurNet::BBS::Base (
    '$packstring' => 'Z13Z20Z24Z14CISSLLZ16Z8Z50Z50Z39',
    '$packsize'   => 256,
    '@packlist'   => [
        qw/userid realname username passwd uflag userlevel numlogins 
           numposts firstlogin lastlogin lasthost remoteuser email 
           address justify month day year reserved state/
    ],
);

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{_hash}{uid} ||= $self->{recno} - 1;
    $self->{_hash}{name} ||= $self->{id};
    return if exists $self->{_hash}{$key};

    if ($self->contains($key)) {
	my $buf = '';

	open(my $USR, "$self->{bbsroot}/.PASSWDS") or die "can't open .PASSWDS";
	seek $USR, $self->{recno} * $packsize, 0;
	read $USR, $buf, $packsize;
	close $USR;

	@{$self->{_hash}}{@packlist} = unpack($packstring, $buf);
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";
    }

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        $self->{id},
        'home',
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($self->contains($key)) {
 	$self->refresh_meta($key);
	$self->{_hash}{$key} = $value;

	open(my $USR, '+<', "$self->{bbsroot}/.PASSWDS")
	    or die "can't open .PASSWDS";
	seek $USR, $self->{recno} * $packsize, 0;
        print $USR pack($packstring, @{$self->{_hash}}{@packlist});
	close $USR;
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";

	$self->{_hash}{$key} = $value;
    }

    return 1;
}

1;

