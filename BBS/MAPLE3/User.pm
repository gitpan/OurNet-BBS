# $File: //depot/OurNet-BBS/BBS/MAPLE3/User.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::MAPLE3::User;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot id recno _cache/;

use enum 'BITMASK:PERM_',
    qw/BASIC CHAT PAGE POST VALID MBOX CLOAK XEMPT/,		# Basic
    qw/P9 P10 P11 P12 P13 P14 P15 P16/,				# Special
    qw/DENYPOST DENYCHAT DENYTALK DENYMAIL DENY5 DENY6 DENYLOGIN PURGE/,
    qw/BM SEECLOAK ADMIN3 ADMIN4 ACCOUNTS CHATROOM BOARD/;	# Admin

use constant PERM_SYSOP	     => 0x80000000; # enum bug: will overflow
use constant PERM_DEFAULT    => (PERM_BASIC|PERM_CHAT|PERM_PAGE|PERM_POST);
use constant PERM_ADMIN      => (PERM_BOARD | PERM_ACCOUNTS | PERM_SYSOP);
use constant PERM_ALLBOARD   => (PERM_SYSOP);
use constant PERM_LOGINCLOAK => (PERM_SYSOP | PERM_ACCOUNTS);
use constant PERM_SEEULEVELS => PERM_SYSOP;
use constant PERM_SEEBLEVELS => (PERM_SYSOP | PERM_BM);
use constant PERM_READMAIL   => PERM_BASIC;
use constant PERM_INTERNET   => PERM_VALID;
use constant PERM_FORWARD    => PERM_INTERNET;
use constant GEM_QUIT        => -2;
use constant GEM_VISIT       => -1;
use constant GEM_USER        => 0;
use constant GEM_RECYCLE     => 1;
use constant GEM_MANAGER     => 2;
use constant GEM_SYSOP       => 3;

BEGIN {
    __PACKAGE__->initvars(
	'$packstring' => 'iZ13Z14CZ20Z24IiiILLLLZ32iLZ60Z60Z60Z60Z120L',
	'$packsize'   => 512,
	'@packlist'   => [ qw(
	    userno userid passwd signature realname username userlevel 
	    numlogins numposts ufo firstlogin lastlogin staytime tcheck 
	    lasthost numemail tvalid email address justify vmail ident 
	    vtime
	) ],
    );
}

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

sub refresh_meta {
    my $self = shift;
    my $key  = shift;

    return if $key and exists $self->{_cache}{$key};

    my $path = "$self->{bbsroot}/usr/".
              lc(substr($self->{id}, 0, 1)."/$self->{id}");

    local $/;

    unless (-d $path) {
        mkdir $path or die "cannot mkdir $path\n";

        open(my $USR, '>', "$path/.ACCT") or die "cannot open: $path/.ACCT";

        $self->{_cache}{userno} = (stat("$self->{bbsroot}/.USR"))[7] / 16;
        $self->{_cache}{userid} = $self->{id};
        $self->{_cache}{userlevel} = 15;
        $self->{_cache}{ufo} = 15;
        print $USR pack($packstring, @{$self->{_cache}}{@packlist});
        close $USR;

        open($USR, '>>', "$self->{bbsroot}/.USR")
	    or die "cannot open: $path/.USR";
        print $USR pack("LZ12", time(), $self->{id});
        close $USR;
    }

    if (!defined($key) or $self->contains($key)) {
	open my $USR, "$path/.ACCT" or die "cannot: open $path/.ACCT";
	@{$self->{_cache}}{@packlist} = unpack($packstring, <$USR>);
	close $USR;

	no warnings 'numeric';

	$self->{recno} ||= $self->{_cache}{userno} + 1;
	$self->{_cache}{uid} ||= $self->{recno} - 1;
	$self->{_cache}{name} ||= $self->{id};

	return 1;
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
	    "$path/$key";
    }

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_cache}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        'usr/'.lc(substr($self->{id}, 0, 1)."/$self->{id}").
        '',
        '',
        '.DIR',
        '',
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);

    my $path = "$self->{bbsroot}/usr/".
		lc(substr($self->{id}, 0, 1)."/$self->{id}");

    if ($self->contains($key)) {
	$self->{_cache}{$key} = $value;

	open my $USR, '>', "$path/.ACCT";
	print $USR pack($packstring, @{$self->{_cache}}{@packlist});
	close $USR;
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
	    "$path/$key" unless $self->{_cache}{$key};

	$self->{_cache}{$key} = $value;
    }
}

1;

