package OurNet::BBS::Client;
$OurNet::BBS::Client::VERSION = '0.1';

use strict;
use RPC::PlClient;
use Digest::MD5 qw/md5/;
use OurNet::BBS::Authen;

use fields qw/id remote_ref optree _phash/;
use vars qw/$AUTOLOAD/;

my $OP = $OurNet::BBS::Authen::OP;

my @delegators;

sub new {
    my $class = shift;
    my ($self, $proxy);

    tie %{$self}, $class, @_;
    tie @{$proxy}, 'OurNet::BBS::ClientProxy', $self;
    return bless($proxy, $class);
}

# spawn (optree_id)
sub spawn {
    my $parent = shift;
    my ($self, $proxy);

    print "SPAWN: $parent @_\n" if $OurNet::BBS::DEBUG;

    tie %{$self}, ref($parent);
    tied(%{$self})->{id} = $parent->{id};
    tied(%{$self})->{remote_ref} = shift;
    tied(%{$self})->{optree} = shift;

    tie @{$proxy}, 'OurNet::BBS::ClientProxy', $self;
    
    return bless($proxy, ref($parent));
}

sub TIEHASH {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };
    if (@_) {
        $self->{id} = 1 + scalar @delegators; # 1 more than max
        my $client = $delegators[$self->{id}] = RPC::PlClient->new(
            peeraddr    => shift,
            peerport    => shift || 7978,
            application => 'OurNet::BBS::Server',
            version     => $OurNet::BBS::Client::VERSION,
	    maxmessage  => (1 << 31),
#	    compression => 'gzip',
        )->ClientObject('OurNet::BBS::Server', 'spawn');

	$self->{remote_ref} = $delegators[$self->{id}]->rootref();

        # [negotiation procedure]
	# phase 0: send available suites, let server choose one
	# phase 1: receive public key from server, import to keyring
	# phase 2: generated random session key of the correct size
	#          and use the public key to encrypt it
	# phase 3: send the encrypted sessions key back

	my @server_suite = $client->getsuite();
	my $cipher;

	if (@server_suite and $cipher = OurNet::BBS::Authen->suites(
	    @server_suite)) {
	    my ($server_auth, $server_pubkey) = $client->getauth($cipher);

	    print "[Client] agreed on cipher: $cipher" if $OurNet::BBS::DEBUG;

	    if ($server_pubkey) {
		print ", negotiating..." if $OurNet::BBS::DEBUG;
		secure_cipher(
		    $client, $cipher, $server_auth, $server_pubkey, @_
		);
		print "done.\n" if $OurNet::BBS::DEBUG;
	    }
	    else {
		print " in insecure mode.\n" if $OurNet::BBS::DEBUG;
		$client->{cipher} = $cipher->new($server_auth);
	    }
	}
	else {
	    print "[Client] warning: using plaintext communication.\n";
	}
    }
    
    bless $self, $class;
    return $self;
}

sub make_key {
    my $keysize = shift;
    my $session_key = md5(rand());
    $session_key .= md5(rand()) unless length($session_key) >= $keysize;

    return substr($session_key, 0, $keysize);
}

sub secure_cipher {
    my ($client, $cipher, $server_auth, $server_pubkey) = splice(@_, 0, 4);

    my $auth = OurNet::BBS::Authen->new($server_auth);
    $auth->import_key($server_pubkey);

    my $keysize = $cipher->keysize ||
	($cipher eq 'Crypt::Blowfish' ? 56 : 8);

    my $session = make_key($cipher->keysize);
    my $authcrypt = $auth->encrypt($session);
    my $mode = $client->setauth($authcrypt);

    $client->{cipher} = $cipher->new($session);

    if ($mode) {
	die "login failed: insufficient authentication info\n" 
		    unless authenticate($auth, $client, @_);
    }
}

sub authenticate {
    my ($auth, $client, $keyid, $login, $passphrase) = @_;

    return unless $keyid and $login and defined $passphrase;

    $auth->{keyid} = $keyid;
    $auth->setpass($passphrase);

    my $challenge = $client->setlogin($login);

    die "[Client] login failed: no public key info.\n" 
	if $challenge eq $OP->{STATUS_NO_PUBKEY};

    if ($challenge eq $OP->{STATUS_OK}) {
	print "challenge: $challenge\n";
	$challenge = $client->setpubkey($auth->export_key());
    }

    die "[Client] login failed: public key info mismatch.\n" 
	if $challenge eq $OP->{STATUS_BAD_PUBKEY};

    die "[Client] login failed: signature rejected by server.\n"
	if $client->setsign($auth->clearsign($challenge)) == 
	   $OP->{STATUS_BAD_SIGNATURE};

    return 1;
}

sub FETCH {
    my ($self, $key) = @_;

    ${$self->{_phash}} = $key;
    return 1;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my ($ego, $op);

    return unless rindex($AUTOLOAD, '::') > -1;
    $AUTOLOAD = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);

    if (tied(%{$self})) {
        $op = "OBJECT_$AUTOLOAD";
        $ego = tied(%{tied(%{$self})->{_hash}});
    }
    elsif (exists $self->{_hash}) {
        $op = "ARRAY_$AUTOLOAD";
        $ego = tied(%{$self->{_hash}});
    }
    else {
        $op = "HASH_$AUTOLOAD";
        $ego = $self;
    }

    # debug "<call: $prefix.$AUTOLOAD (@_)>\n";
    my @result = $delegators[$ego->{id}]->invoke(
	$OP->{$op} || $op, $ego->{optree}, @_
    );
    # debug "</call>\n";

    if (@result == 4 and !$result[0] and my $opcode = $result[1]) {
        return $ego->spawn($result[2], $result[3])
	    if $OP->{$opcode} eq 'OBJECT_SPAWN';

        die "$result[2] $result[3] [$OP->{$opcode}]\n";
    }

    return wantarray ? @result : $result[0];
}

1;


package OurNet::BBS::ClientProxy;
*OurNet::BBS::ClientProxy::AUTOLOAD = *OurNet::BBS::Client::AUTOLOAD;

sub TIEARRAY {
    my ($class, $hash) = @_;
    my $flag = undef;
    my $self = {_flag => \$flag, _hash => $hash};

    (tied %$hash)->{_phash} = (\$flag);
    return bless($self, $class);
}

sub STORE {
    my ($self, $key) = splice(@_, 0, 2);
    my $hash = $self->{_hash};
    # print "STORE: $key $hash\n";
    return $hash if $key == 0;
    # print "$self AFETCH: $key\n";
    my $ego = tied %{$hash};

    no strict 'refs';

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

        # hash store: VERY CRUDE HACK!
        ${ref($ego).'::AUTOLOAD'} = '::STORE';
        return ($ego->AUTOLOAD($key, @_))[0];
    }
    else {
        ${ref($ego).'::AUTOLOAD'} = '::STORE';
        return ($ego->AUTOLOAD($key, @_))[0];
    }
}

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{_hash};
    # print "FETCH: $key $hash\n";
    return $hash if $key == 0;
    # print "$self AFETCH: $key\n";
    my $ego = tied %{$hash};

    no strict 'refs';

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

        # hash fetch: VERY CRUDE HACK!
        ${ref($ego).'::AUTOLOAD'} = '::FETCH';
        return ($ego->AUTOLOAD($key))[0];
    }
    else {
        ${ref($ego).'::AUTOLOAD'} = '::FETCHARRAY';
        return ($ego->AUTOLOAD($key))[0];
    }
}

sub DESTROY {}

1;
