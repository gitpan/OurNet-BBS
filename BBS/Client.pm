# $File: //depot/OurNet-BBS/BBS/Client.pm $ $Author: autrijus $
# $Revision: #18 $ $Change: 1255 $ $DateTime: 2001/06/21 10:57:45 $

package OurNet::BBS::Client;

use strict;
use RPC::PlClient;
use Digest::MD5 qw/md5/;
use OurNet::BBS::Authen;

use fields qw/id remote_ref optree _phash/;
use enum qw/BITMASK:CIPHER_ NONE BASIC PGP/;
use enum qw/BITMASK:AUTH_   NONE CRYPT PGP/;

our ($AUTOLOAD, $Port);

$Port = 7978;

my $OP = $OurNet::BBS::Authen::OP;
my (%Cache, @delegators);

sub new {
    my $class = shift;
    my ($self, $proxy);

    tie %{$self}, $class, @_;
    tie @{$proxy}, 'OurNet::BBS::ClientArrayProxy', $self;
    return bless($proxy, $class);
}

# spawn (optree_id)
sub spawn {
    my $parent = shift;
    my ($self, $proxy);

    show("SPAWN: @_\n");

    tie %{$self}, ref($parent);
    tied(%{$self})->{id} = $parent->{id};
    tied(%{$self})->{remote_ref} = shift;
    tied(%{$self})->{optree} = shift;

    tie @{$proxy}, 'OurNet::BBS::ClientArrayProxy', $self;
    
    return bless($proxy, ref($parent));
}

sub TIEHASH {
    my ($class, $peeraddr, $peerport, 
	$keyid, $user, $pass, $cipher_level, $auth_level) = @_; 

    my $self = fields::new($class);

    if ($#_) { # if not only class...
        $self->{id} = scalar @delegators; # 1 more than max

        $delegators[$self->{id}] = RPC::PlClient->new(
            peeraddr    => $peeraddr,
            peerport    => $peerport || $Port,
            application => 'OurNet::BBS::Server',
            version     => $OurNet::BBS::Authen::VERSION,
        )->ClientObject('__', 'spawn');

	my $client = $delegators[$self->{id}];

## Initialization #####################################################
# spawn a handle and get server's accepted modes.

	($cipher_level, $auth_level) = $client->handshake(
	    OurNet::BBS::Authen->adjust(
		$cipher_level, $auth_level, $keyid, 1
	    )
	) or print "[Client] initialization failed.\n" and die;

	my ($status, $auth) = negotiate_cipher($client, $cipher_level)
	    or print "[Client] cipher negotiation failed.\n" and die;

	negotiate_auth($client, $auth_level, $auth, $keyid, $user, $pass)
	    or print "[Client] authentication failed.\n" and die;

	$self->{remote_ref} = negotiate_locate($client)
	    or print "[Client] object location failed.\n" and die;

	show("done!\n");
    }
    
    bless ($self, $class);
    return $self;
}

sub negotiate_locate {
    my $client = shift;

    return $client->locate(@_);
}


sub make_auth {
    my ($keyid, $pubkey) = @_;

    my $auth = OurNet::BBS::Authen->new($keyid) or return;
    $auth->import_key($pubkey);

    return $auth;
}

sub negotiate_cipher {
    my ($client, $mode, $auth) = @_;

## Seed Phase #########################################################
# gets supported cipher suites and (optionally) server's public key

    my $cipher = OurNet::BBS::Authen->suites($client->get_suites)
	if $mode & (CIPHER_BASIC | CIPHER_PGP);

    show("[Client] agreed on cipher: $cipher ") if $cipher;

    if ($cipher and $mode & CIPHER_PGP) {
	$auth = make_auth($client->get_pubkey);

## Cipher Phase #######################################################
# try each mutually acceptable cipher schemes in turn to set cipher

	if ($auth and cipher_pgp($client, $cipher, $auth)) {
	    show("in secure mode.\n");
	    return(CIPHER_PGP, $auth);
	}
    }

    if ($cipher and $mode & CIPHER_BASIC) {
	if (cipher_basic($client, $cipher)) {
	    show("in insecure mode.\n");
	    return(CIPHER_BASIC, $auth);
	}
    }

    if ($mode & CIPHER_NONE and cipher_none($client)) {
	show("[Client] warning: using plaintext communication.\n");
	return(CIPHER_NONE, $auth);
    }

    show("failed!\n");
    return;
}

sub cipher_pgp {
    my ($client, $cipher, $auth) = @_;

    my $keysize = $cipher->keysize || (
	$cipher eq 'Crypt::Blowfish' ? 56 : 8
    );

    # make session key
    my $session_key = md5(rand);
    $session_key .= md5(rand) until length($session_key) >= $keysize;
    $session_key = substr($session_key, 0, $keysize);

    my $authcrypt = $auth->encrypt($session_key) or return; # encrypt it
    $client->cipher_pgp($cipher, $authcrypt) or return;	    # send it back

    $client->{client}{cipher} = $cipher->new($session_key);

    return $auth;
}

sub cipher_basic {
    my ($client, $cipher) = @_;
    my ($status, $session) = $client->cipher_basic($cipher) or return;

    return ($client->{client}{cipher} = $cipher->new($session));
}

sub cipher_none {
    my ($client) = @_;
    return $client->cipher_none;
}

## Auth Phase #########################################################
# log in by trying each mutually acceptable authentication schemes

sub negotiate_auth {
    my ($client, $mode, $auth, $keyid, $user, $pass) = @_;

    # Authentication Negotiation
    show("[Client] begin authentication...");

    if ($mode & AUTH_PGP and $auth ||= make_auth($client->get_pubkey)) {
	# public key authentication
	show("trying pubkey...");
	return AUTH_PGP if auth_pgp(
	    $client, $auth, $keyid, $user, $pass
	);
    }

    if ($mode & AUTH_CRYPT and $user) {
	# crypt-based authentication
	show("trying crypt...");
	return AUTH_CRYPT if auth_crypt($client, $user, $pass);
    }

    if ($mode & AUTH_NONE and $client->auth_none) {
	# no authentication at all
	show("fallback to none...");
	return AUTH_NONE;
    }

    show("failed!\n");
    return;
}

sub auth_pgp {
    my ($client, $auth, $keyid, $login, $passphrase) = @_;
    return unless $keyid and $login and defined $passphrase;

    $auth->{keyid} = $keyid;
    $auth->setpass($passphrase);

    my $challenge = $client->auth_pgp($login);

    if ($challenge eq $OP->{STATUS_NO_USER}) {
	show('no such user! ');
	return;
    }
    elsif ($challenge eq $OP->{STATUS_NO_PUBKEY}) {
	show('no public key info! ');
	return;
    }
    elsif ($challenge eq $OP->{STATUS_OK}) {
	show("challenge($challenge)");
	$challenge = $client->set_pubkey($auth->export_key);
    }

    if ($challenge eq $OP->{STATUS_BAD_PUBKEY}) {
	show('public key mismatch! ');
	return;
    }

    my $signature = $auth->clearsign($challenge)
	or show('cannot make signature! ') and return;

    if ($client->set_sign($signature) eq $OP->{STATUS_BAD_SIGNATURE}) {
	show('signature rejected! ');
	return;
    }

    return 1;
}

sub auth_crypt {
    my ($client, $user, $pass) = @_;
    my ($status, $salt) = $client->auth_crypt($user) or return;

    if ($status eq $OP->{STATUS_NO_USER}) {
	show('no such user! ');
	return;
    }

    return (
	$client->set_crypted(crypt($pass, $salt)) eq $OP->{STATUS_ACCEPTED}
    );
}

sub auth_none {
    my ($client) = @_;
    return $client->auth_none;
}

sub quit {
    foreach my $client (@delegators) {
	$client->quit if $client;
    }

    undef @delegators;
}

sub show {
    no warnings 'once';
    print $_[0] if $OurNet::BBS::DEBUG;
}

## Connected ##########################################################
# do the real job via AUTOLOAD passing and ArrayHashMonster magic

sub AUTOLOAD {
    my ($ego, $op);

    no strict 'refs';

    my $action = substr($AUTOLOAD, (
	(rindex($AUTOLOAD, ':') + 1) || return
    ));

    # special-casing the FETCH method
    if (rindex($action, '__') > -1) {
	chop $action; chop $action;
    }

    # install a closure-based handler for future use instead of AUTOLOAD
*{$AUTOLOAD} = sub {
    my $self = shift;

    if (tied(%{$self})) {
        $op = "OBJECT_$action";
        $ego = tied(%{tied(%{$self})->{_hash}});
    }
    elsif (exists $self->{_hash}) {
        $op = "ARRAY_$action";
        $ego = tied(%{$self->{_hash}});
    }
    else {
        $op = "HASH_$action";
        $ego = $self;
    }

    my @result = $delegators[$ego->{id}]->__(
	$OP->{$op} || $op, $ego->{optree}, @_
    );

    if (@result == 4 and !$result[0] and my $opcode = $result[1]) {
        return $ego->spawn(@result[2, 3])
	    if $OP->{$opcode} eq 'OBJECT_SPAWN';

	return undef if $OP->{$opcode} eq 'STATUS_IGNORED';

        die "@result[2, 3] [$OP->{$opcode}]\n";
    }

    return wantarray ? @result : $result[0];
} unless exists(&{$AUTOLOAD});

    goto &{$AUTOLOAD};
}

sub FETCH {
    my ($self, $key) = @_;

    ${$self->{_phash}} = $key;

    return 1;
}

# couldn't care less
sub UNTIE {}
sub DESTROY {}

1;

## ArrayProxy #########################################################
# Resolves the second level tie intelligently

package OurNet::BBS::ClientArrayProxy;

# delegate FETCHSIZE etc to OurNet::BBS::Client's handler
*OurNet::BBS::ClientArrayProxy::AUTOLOAD = *OurNet::BBS::Client::AUTOLOAD;

# constructor; $flag is usually undef
sub TIEARRAY {
    my ($class, $hash, $flag) = @_;
    my $self = {_flag => \$flag, _hash => $hash};

    (tied %$hash)->{_phash} = (\$flag);
    return bless($self, $class);
}

sub STORE {
    my ($self, $key) = splice(@_, 0, 2);
    my $hash = $self->{_hash};
    return $hash if $key == 0;

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};
    }

    return scalar(tied(%{$hash})->STORE($key, @_));
}

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{_hash};
    return $hash if $key == 0;

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

	return scalar(tied(%{$hash})->FETCH__($key));
    }
    else {
	return scalar(tied(%{$hash})->FETCHARRAY($key));
    }
}

# couldn't care less
sub UNTIE {}
sub EXTEND {}
sub DESTROY {}

1;
