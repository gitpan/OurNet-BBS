# $File: //depot/OurNet-BBS/BBS/Server.pm $ $Author: autrijus $
# $Revision: #38 $ $Change: 1628 $ $DateTime: 2001/08/31 03:47:07 $

package OurNet::BBS::Server;

use strict;
use OurNet::BBS::Authen;
use base qw/RPC::PlServer/;

our ($Port, $Mode, $Childs, $LocalAddr);

$OurNet::BBS::Server::VERSION = $OurNet::BBS::Authen::VERSION; 

$Port      = 7979;
$Mode      = 'fork';
$Childs    = undef; # max. concurrent connections.
$LocalAddr = 'localhost';

sub daemonize {
    my ($class, $root, $port) = splice(@_, 0, 3);

    # Server options below can be overwritten in the config file or
    # on the command line.
    __::daemonize($root, __PACKAGE__->new({
        pidfile     => 'none',
        facility    => 'daemon', # Default
	localaddr   => $LocalAddr,
        localport   => $port || $Port,
        methods     => {
	    'OurNet::BBS::Server' => {
		## Default ##########
		NewHandle	=> 1,
		CallMethod	=> 1,
		DestroyHandle	=> 1,
	    },
	    '__' => {
		## Initialization ###
		spawn		=> 1,
		handshake	=> 1,
		## Seed Phase #######
		get_suites	=> 0,
		get_pubkey	=> 0,
		## Cipher Phase #####
		cipher_pgp	=> 0,
		cipher_basic	=> 0,
		cipher_none	=> 0,
		## Auth Phase #######
		auth_pgp	=> 0,
		    set_pubkey	=> 0,
		    set_sign	=> 0,
		auth_crypt	=> 0,
		    set_crypted	=> 0,
		auth_none	=> 0,
		## Locate Phase #####
		locate		=> 0,
		relay		=> 0,
		## Connected ########
		__		=> $OurNet::BBS::BYPASS_NEGOTIATION,
		####################
		quit		=> $OurNet::BBS::BYPASS_NEGOTIATION,
		####################
	    },
        },    
        mode        => $Mode,
	childs      => $Childs,
    }), @_);
}

#######################################################################

package __;

use strict;
use Digest::MD5 qw/md5 md5_hex/;

my $OP     = $OurNet::BBS::Authen::OP;
my $OPREV  = $OurNet::BBS::Authen::OPREV;
my @OPTREE = ('');

my ($ROOT, $Server, $Auth, @CipherSuites, %Cache, %Perm);
my ($CipherLevel, $AuthLevel, $CipherMode, $AuthMode, $GuestId);

use enum qw/BITMASK:CIPHER_ NONE BASIC PGP/;
use enum qw/BITMASK:AUTH_ NONE CRYPT PGP/;

use constant OP_WRITE  => ' STORE DELETE ';
use constant OP_IGNORE => ' daemonize DESTROY initvars writeok readok '.
			  ' new timestamp fillmod fillin remove ';
sub daemonize {
    ($ROOT, $Server, my (
	$keyid, $passphrase, $cipher_level, $auth_level, $guest_id
    )) = @_;

    ($CipherLevel, $AuthLevel) = OurNet::BBS::Authen->adjust(
	$cipher_level, $auth_level, ($passphrase and $keyid)
    );

    if ($CipherLevel & CIPHER_PGP or $AuthLevel & AUTH_PGP) {
	$Auth = OurNet::BBS::Authen->new($keyid, $passphrase);

	die "can't access private key; please check passphrase.\n"
	    unless $Auth->test;

	die "can't export public key; please check key ring.\n"
	    unless $OurNet::BBS::Authen::Pubkey;
    }

    if ($AuthLevel & (AUTH_CRYPT | AUTH_PGP)) {
	if (UNIVERSAL::isa($ROOT, 'OurNet::BBS')) {
	    local $@;
	    no warnings;

	    my $sysop = eval { $ROOT->{users}{SYSOP} } || [];

	    $AuthLevel &= ~AUTH_CRYPT unless eval{
		$sysop->{passwd} 
	    } and !$@;

	    undef $@;

	    $AuthLevel &= ~AUTH_PGP unless eval{
		$sysop->{plans} 
	    } or !$@;
	}
	else {
	    $AuthLevel &= ~(AUTH_CRYPT | AUTH_PGP)
	}
    }

    if ($AuthLevel & AUTH_NONE and $GuestId = $guest_id) {
	$AuthLevel &= ~AUTH_NONE unless exists $ROOT->{users}{$guest_id};
    }

    if ($CipherLevel & (CIPHER_PGP | CIPHER_BASIC)) {
	$CipherLevel &= ~(CIPHER_PGP | CIPHER_BASIC)
	    unless @CipherSuites = OurNet::BBS::Authen->suites;
    }

    die "no cipher modes available"	    unless $CipherLevel;
    die "no authentication modes available" unless $AuthLevel;

    show("[Server] OurNet service started.\n");

    $Server->Bind;
}

## Initialization #####################################################

sub spawn {
    return (bless(\$ROOT, __PACKAGE__));
}

sub handshake {
    my ($self, $cipher_level, $auth_level) = @_;

    nextstate('get_suites', 'get_pubkey', 'cipher_none');
    return ($CipherLevel & $cipher_level, $AuthLevel & $auth_level);
}

## Seed Phase #########################################################

sub get_suites {
    nextstate('cipher_basic');
    return @CipherSuites;
}

sub get_pubkey {
    nextstate($CipherMode ? 'auth_pgp' : 'cipher_pgp');
    return ($Auth->{who}, $OurNet::BBS::Authen::Pubkey || die "can't export");
}

## Cipher Phase #######################################################

sub cipher_pgp {
    my ($self, $cipher, $authcrypt) = @_;
    return unless ($CipherLevel & CIPHER_PGP and $cipher and $authcrypt);

    my $session_key;

    $cipher = OurNet::BBS::Authen->suites($cipher) and
    $session_key = $Auth->decrypt($authcrypt)      and
    $self->{newciph} = $cipher->new($session_key) 
	or nextstate() and return;

    nextstate('auth_pgp', 'auth_crypt', 'auth_none');
    return ($CipherMode = CIPHER_PGP);
}

sub cipher_basic {
    my ($self, $cipher) = @_;
    return unless $CipherLevel & CIPHER_BASIC and $cipher;

    $cipher = OurNet::BBS::Authen->suites($cipher)
	or nextstate() and return;

    my $keysize = $cipher->keysize || (
	$cipher eq 'Crypt::Blowfish' ? 56 : 8
    );

    # make session key
    my $session_key = md5(rand);
    $session_key .= md5(rand) until length($session_key) >= $keysize;
    $session_key = substr($session_key, 0, $keysize);

    $self->{newciph} = $cipher->new($session_key)
	or nextstate() and return;

    # XXX AUTH_CRYPT over CIPHER_BASIC considered harmful!
    nextstate('auth_pgp', 'auth_crypt', 'auth_none'); 
    return ($CipherMode = CIPHER_BASIC, $session_key);
}

sub cipher_none {
    my ($self) = @_;
    return unless $CipherLevel & CIPHER_NONE;

    $AuthLevel &= ~AUTH_CRYPT;

    nextstate('auth_pgp', 'auth_crypt', 'auth_none');
    return ($CipherMode = CIPHER_NONE);
}

## Auth Phase #########################################################

sub auth_pgp {
    my ($self, $login) = @_;
    return unless $AuthLevel & AUTH_PGP;

    show("[Server] $login: login");

    $Auth->{user}  = $ROOT->{users}{$login} 
	or return $OP->{STATUS_NO_USER};
    $Auth->{login} = $login;

    my $plan = ($Auth->{user})->{plans} || '';

    if ($plan =~ /^#[\s\t]*pubkey:[\s\t]*(?:\d+\w\/)?([^\s]+)/) {
	$Auth->{keyid} = $1;
    }
    else {
	show("...failed! (no pubkey id)");
	nextstate();
	return $OP->{STATUS_NO_PUBKEY};
    }

    my $pubkey = ($Auth->{user})->{pubkey};

    if ($pubkey and $pubkey eq $Auth->export_key) {
	nextstate('set_sign');
	return ($Auth->{challenge} = md5_hex(rand));
    }
    else {
	nextstate('set_pubkey');
	return $OP->{STATUS_OK};
    }
}

sub set_pubkey {
    my ($self, $pubkey) = @_;

    show("...setpubkey");;

    $Auth->import_key($pubkey);

    if ($pubkey eq $Auth->export_key) {
	$Auth->{user}{pubkey} = $pubkey or return;
	nextstate('set_sign');
	return ($Auth->{challenge} = md5_hex(rand));
    }
    else {
	show("...failed! (keyid doesn't match)\n");;
	nextstate();
	return $OP->{STATUS_BAD_PUBKEY};
    }
}

sub set_sign {
    my ($self, $signature) = @_;

    show("...setsign");

    my $response = $Auth->verify($signature);

    if (!$response or
	index($response, "key ID $Auth->{keyid}") > -1	and
	index($response, "gpg: BAD signature") == -1	and
	index($signature, "$Auth->{challenge}\n") > -1) 
    {
	show("...done!\n");
	nextstate('locate', 'relay');
	return ($OP->{STATUS_ACCEPTED}, AUTH_PGP);
    }
    else { 
	show("...failed! ($signature, $response)\n");
	nextstate();
	return $OP->{STATUS_BAD_SIGNATURE}
    }
}

sub auth_crypt {
    my ($self, $login) = @_;
    return unless $AuthLevel & AUTH_CRYPT;

    $Auth->{user} = $ROOT->{users}{$login} or return $OP->{NO_USER};

    my $passwd = ($Auth->{user})->{passwd};
    return unless length($passwd);

    $Auth->{login} = $login;

    show("[Server] $login: login");;
    nextstate('set_crypted');
    return ($OP->{STATUS_OK}, substr($passwd, 0, 2));
}

sub set_crypted {
    my ($self, $crypted) = @_;

    if (($Auth->{user})->{passwd} eq $crypted) {
	show("...done!\n");;
	nextstate('locate', 'relay');
	return ($OP->{STATUS_ACCEPTED}, $AuthMode = AUTH_CRYPT); 
    }

    show("...failed! (crypt mismatch)\n");;
    nextstate();
    return $OP->{STATUS_BAD_SIGNATURE};
}

sub auth_none {
    return unless $AuthLevel & AUTH_NONE;

    if ($Auth->{login} = $GuestId) {
	$Auth->{user} = $ROOT->{users}{$GuestId} or return $OP->{NO_USER};
    }
    else {
	undef $Auth->{user};  # clean up previous auth
	undef $Auth->{login}; # clean up previous auth
    }

    nextstate('locate', 'relay');
    return ($OP->{STATUS_ACCEPTED}, $AuthMode = AUTH_NONE); 
}

## Locate Phase #######################################################

sub locate {
    nextstate('__', 'quit');
    return "$ROOT";
}

sub relay {
    nextstate('__', 'quit');
    return "$ROOT"; # XXX unimplemented
}

## Connected ##########################################################

sub __ {
    my $obj    = ${$_[0]};
    my $parent = $_[2];
    my ($op, $param, @ret);

    @_[2, 3] = ([map {
	ref($_) eq __PACKAGE__ ? __($_[0], undef, ${$_}, undef) : $_ 
    } @_[3..$#_]], $_[2]); $#_ = 3;

    while ($_[-1]) {
	@_[$#_ .. $#_ + 2] = @OPTREE[$_[-1] .. $_[-1] + 2];
    }

    foreach my $i (2 .. (scalar @_ / 2)) { return eval { 
	no warnings 'exiting'; # intended! arbitary! 

	my ($op, $param) = @_[
	    ($#_ - ($i * 2)) + 2,
	    ($#_ - ($i * 2)) + 3,
	];

	unless (defined $op) {
	    return $obj;
	}

	my $action = $OPREV->{$op};
	$op        = $OP->{$op} if $action; # do name translation
	$action  ||= substr($op, index($op, '_') + 1);

	if ((index(OP_IGNORE, " $action ") > -1)) {
	    show("ignored op: $obj $op\n");
	    return('', $OP->{STATUS_IGNORED}, $action, '');
	}

	if (not $Perm{"$obj $op"} and $Auth->{user}
	    and substr(ref($obj), 0, 11) eq 'OurNet::BBS'
	) {
	    return (
		'', $OP->{STATUS_FORBIDDEN}, $action, "not permitted: $obj"
	    ) unless (
		(index(OP_WRITE, " $action ") > -1)
		    ? $obj->writeok($Auth->{user}, $action, $param)
		    : $obj->readok($Auth->{user}, $action, $param)
	    );

	    $Perm{"$obj $op"} = 1;
	}

        if ($op =~ m/^OBJECT_/) {
	    return { %{$obj} } if $action eq 'SPAWN';
	    return ref($obj)   if $action eq 'REF';

            my @ret = $obj->$action(@{$param});
            $obj = $ret[0] and next unless $#ret; 
            return @ret; # return unless single arg
	}

        my $arg = $param->[0] if @{$param};

        if ($op eq 'HASH_FETCH') {
	    # perl uses fetch to get val from 2-arg each.
	    $obj = exists $Cache{$obj}{$arg} 
		? delete($Cache{$obj}{$arg}) : $obj->{$arg};
        } elsif ($op eq 'HASH_FIRSTKEY') {
	    my @ret = UNIVERSAL::can($obj, 'FIRSTKEY')
		? $obj->FIRSTKEY
		: (scalar keys(%$obj) ? each(%$obj) : undef);

	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return $ret[0];
        } elsif ($op eq 'HASH_NEXTKEY') {
	    my @ret = UNIVERSAL::can($obj, 'ego') 
		? $obj->NEXTKEY
		: each(%$obj);

	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return $ret[0];
	} elsif ($op eq 'HASH_DESTROY') {
            return;
        } elsif ($op eq 'ARRAY_DESTROY') {
            return;
        } elsif ($op eq 'ARRAY_FETCH') {
            $obj = $obj->[$arg];
	    # print "$op $obj $arg\n"; 
        } elsif ($op eq 'ARRAY_FETCHSIZE') {
            return scalar @{$obj};
        } elsif ($op eq 'ARRAY_DEREFERENCE') {
            return @{$obj};
        } elsif ($op eq 'HASH_DEREFERENCE') {
            return %{$obj};
        } elsif ($op eq 'ARRAY_STORE') {
            $obj = $obj->[$arg] = $param->[1];
            # return $obj->[$arg] = $param->[1] ? 1 : undef;
        } elsif ($op eq 'HASH_STORE') {
	    $obj = $obj->{$arg} = $param->[1];
	    # return $obj->{$arg} = $param->[1] ? 1 : undef;
        } elsif ($op eq 'ARRAY_DELETE') {
            $obj = (delete $obj->[$arg]);
        } elsif ($op eq 'HASH_DELETE') {
            $obj = (delete $obj->{$arg});
        } elsif ($op eq 'ARRAY_PUSH') {
            $obj = push(@{$obj}, @{$param});
        } elsif ($op eq 'ARRAY_POP') {
            $obj = pop(@{$obj->{$arg}});
        } elsif ($op eq 'ARRAY_SHIFT') {
            $obj = shift(@{$obj->{$arg}});
        } elsif ($op eq 'HASH_EXISTS') {
            return exists ($obj->{$arg});
        } elsif ($op eq 'ARRAY_EXISTS') {
            return exists ($obj->[$arg]);
        } elsif ($op eq 'ARRAY_UNSHIFT') {
            return (unshift @{$obj}, @{$param});
        } else {
            warn "Unknown OP: $op (@{$param})\n";
	    return ('', $OP->{STATUS_UNKNOWN_OP}, '', '');
        }

	next;
    };

	if ($@) {
	    show("execution failed: $@\n");
	    return ('', $OP->{STATUS_FAILED}, '', $@);
	}
    };

    if (UNIVERSAL::isa(ref($obj), 'UNIVERSAL')) { # is it an overloaded object?
	push @OPTREE, $_[1], $_[2], $parent;
	return ('', $OP->{OBJECT_SPAWN}, "$obj", $#OPTREE - 2);
    }
    else {
	return $obj;
    }
}

sub quit {
    return unless $OurNet::DEBUG;
    exit if $Server->{mode} ne 'fork';
    $Server->{done} = 1;
}

## Utilities ##########################################################

sub show {
    print $_[0] if $OurNet::BBS::DEBUG;
}

sub nextstate {
    my $caller = substr((caller(1))[3], 4); # subroutine name

    # show("|$caller") if @_;

    $Server->{methods}{__}{$caller} = 0;
    $Server->{methods}{__}{$_} = 1 foreach @_;
}

1;

package OurNet::BBS::Server;

#######################################################################
# The following section is a modified version of RPC::PlServer code, 
# with added support on changing cipher mode *after* a CallMethod
# has been made, as well as passing the actual server instance instead
# of the registered object.
#
# Because this makes the new server's behaviour incompatible from
# existing PlRPC's, I choose to fork a specific version just for
# OurNet::BBS's purpose. I'll notify the author once this modification
# proves to be stable and useful enough. 
#
# According to the Artistic License, the copyright information of 
# RPC::PlServer is acknowledged here:
# 
#   PlRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   Copyright (c) 1997,1998  Jochen Wiedmann
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
#
#           Email: joe@ispsoft.de
#           Phone: +49 7123 14887
#
# The source code PlRPC is very possibly on your computer right now,
# since OurNet::BBS::Server depend on that library to run. Nevertheless,
# you may obtain the PlRPC source via the Bundle::PlRPC package from
# CPAN at http://www.cpan.org/.
#
#######################################################################

sub CallMethod ($$$@) {
    my($self, $handle, $method, @args) = @_;
    my($ref, $object);

    my $call_by_instance;
    {
	my $lock = lock($Net::Daemon::RegExpLock)
	    if $Net::Daemon::RegExpLock && $self->{'mode'} eq 'threads';
	$call_by_instance = ($handle =~ /=\w+\(0x/);
    }
    if ($call_by_instance) {
	# Looks like a call by instance
	$object = $self->UseHandle($handle);
	$ref = ref($object);
    } else {
	# Call by class
	$ref = $object = $handle;
    }

    if ($self->{'methods'}) {
	my $class = $self->{'methods'}->{$ref};
	if (!$class  ||  !$class->{$method}) {
	    die "Not permitted for method $method of class $ref";
	}
    }

    no strict 'refs';
    if ($method eq '__') {
	$object->$method(@args);
    }
    else {
	&{"$ref\::$method"}($self, @args);
    }
}

sub Run ($) {
    my $self = shift;
    my $socket = $self->{'socket'};

    while (!$self->Done) {
	my $msg = $self->RPC::PlServer::Comm::Read;
	last unless defined($msg);
	die "Expected array" unless ref($msg) eq 'ARRAY';
	my($error, $command);
	if (!($command = shift @$msg)) {
	    $error = "Expected method name";
	} else {
	    if ($self->{'methods'}) {
		my $class = $self->{'methods'}->{ref($self)};
		if (!$class  ||  !$class->{$command}) {
		    $error = "Not permitted for method $command of class "
			. ref($self);
		}
	    }
	    if (!$error) {
		$self->Debug("Client executes method $command");
		my @result = eval { $self->$command(@$msg) };
		if ($@) {
		    $error = "Failed to execute method $command: $@";
		} else {
		    $self->RPC::PlServer::Comm::Write(\@result);
		}

		if ($self->{newciph}) {
		    $self->{cipher} = $self->{newciph};
		    delete $self->{newciph};
		}
	    }
	}
	if ($error) {
	    $self->RPC::PlServer::Comm::Write(\$error);
	}
    }
}

1;
