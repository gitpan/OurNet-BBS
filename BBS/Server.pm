package OurNet::BBS::Server;
$OurNet::BBS::Server::VERSION = '0.1';

use strict;
use RPC::PlServer;
use Digest::MD5 qw/md5 md5_hex/;
use OurNet::BBS::Authen;
use base qw/RPC::PlServer/;

my $OP    = $OurNet::BBS::Authen::OP;
my $OPREV = $OurNet::BBS::Authen::OPREV;

my ($Auth, $Server, %Perm, $ROOT, @OPTREE);

@OPTREE = ('');

sub daemonize {
    shift if ($_[0] eq __PACKAGE__); # allow either -> or ::

    $ROOT = shift;

    # Server options below can be overwritten in the config file or
    # on the command line.
    $Server = __PACKAGE__->new({
        pidfile     => 'none',
        facility    => 'daemon', # Default
        localport   => shift || 7978,
        methods     => {
	    'OurNet::BBS::Server' => {
                NewHandle	=> 1,
                CallMethod	=> 1,
                DestroyHandle	=> 1,
                spawn		=> 1,
		rootref         => 1,
                getsuite	=> 1,
                getauth		=> !$_[0],
                setauth		=> !$_[0],
                setlogin	=> !$_[0],
                setpubkey	=> !$_[0],
                setsign		=> !$_[0],
                invoke		=> !$_[0],
                quit		=> $OurNet::BBS::DEBUG,
            },
        },    
	maxmessage  => ( 1 << 31 ),
        mode        => 'fork',   # Recommended for Unix
    });

    if ($_[0]) {
	$Auth = OurNet::BBS::Authen->new(@_);
	die "can't access private key; check passphrase and try again.\n"
	    unless $Auth->test();

	print "[Server] secure connection enabled. available ciphers are:\n";
	print join(
	    ', ', map { m/^Crypt::(.+)$/ ? $1 : $_ }
	    OurNet::BBS::Authen->suites()
	);
	print "\n[Server] entering authenticated permission control mode."
	    if $Auth->{mode};
	print "\n";
	
    }
    $Server->Bind();
}

sub make_key {
    my $keysize = shift;
    my $session_key = md5(rand());
    $session_key .= md5(rand()) unless length($session_key) >= $keysize;

    return substr($session_key, 0, $keysize);
}

sub getsuite {
    $Server->{methods}{'OurNet::BBS::Server'}{getauth} = 1;
    return OurNet::BBS::Authen->suites();
}

sub getauth {
    print "[Server] agreed on cipher: $_[1]\n";

    if (!$Auth) {
	my $cipher = OurNet::BBS::Authen->suites($_[1])
	    or die "malicious cipher";

	my $session = make_key($cipher->keysize());

	$Server->{cipher} = $cipher->new($session);

	return $session;
    } 
    elsif ($Auth->suites($_[1])) {
	$Server->{methods}{'OurNet::BBS::Server'}{setauth} = 1;
	return ($Auth->{who}, $Auth->export_key());
    }
    else {
	die "malicious cipher";
    }
}

sub setauth {
    return unless $Auth;
    $Server->{cipher} = $Auth->{cipher}->new($Auth->decrypt($_[1]));
    $Server->{methods}{'OurNet::BBS::Server'}{invoke}   = !$Auth->{mode};
    $Server->{methods}{'OurNet::BBS::Server'}{setlogin} = $Auth->{mode};
    return $Auth->{mode};
}

sub setlogin {
    die "can't be here" unless $Auth->{mode};
    print "[Server] $_[1]: login";

    $Auth->{login} = $_[1];
    die "not a BBS object" unless substr(ref($ROOT), -5) eq '::BBS';

    print "user: $_[1]";
    $Auth->{user} = $ROOT->{users}{$_[1]} or print "cannot find user";

    my $k = $Auth->{user};
    my $plan = $Auth->{user}{plans};

    $plan =~ /^#[\s\t]*pubkey:[\s\t]*(?:\d+\w\/)?([^\s]+)/ 
	or print "...failed! (no pubkey id)"
	   and return $OP->{STATUS_NO_PUBKEY};

    $Auth->{keyid} = $1;

    my $pubkey = $Auth->{user}{pubkey} or do {
	$Server->{methods}{'OurNet::BBS::Server'}{setpubkey} = 1;
	return $OP->{STATUS_OK};
    };

    my $matched = compare($pubkey);

    $Server->{methods}{'OurNet::BBS::Server'}{setpubkey} = !$matched;
    $Server->{methods}{'OurNet::BBS::Server'}{setsign}   = $matched;

    return $matched ? ($Auth->{challenge} = md5_hex(rand())) 
		    : $OP->{STATUS_OK};
}

sub setpubkey {
    return unless $Auth->{keyid};
    print "...setpubkey";

    my $pubkey = $_[1];

    $Auth->import_key($pubkey);

    print "...failed! (pubkey and key id doesn't match)\n"
	and return $OP->{STATUS_BAD_PUBKEY} unless compare($pubkey);

    $Auth->{user}{pubkey} = $pubkey;
    $Server->{methods}{'OurNet::BBS::Server'}{setsign} = 1;

    return ($Auth->{challenge} = md5(rand()));
}

sub setsign {
    return unless $Auth->{challenge};
    print "...setsign";

    my $response = $Auth->verify($_[1]);

    print "...failed! ($response)\n" and return $OP->{STATUS_BAD_SIGNATURE}
	unless (index($response, "key ID $Auth->{keyid}") > -1) and
	       (index($response, "gpg: BAD signature") == -1) and
	       (index($_[1], "$Auth->{challenge}\n") > -1);

    print "...done!\n";

    $Server->{methods}{'OurNet::BBS::Server'}{invoke} = 1;

    return $OP->{STATUS_ACCEPTED};
}

sub compare {
    print "...comparison";

    return ($_[0] eq $Auth->export_key());
}

sub rootref {
    return \$ROOT;
}

sub spawn {
    return (bless(\$ROOT, $_[0]));
}

my (%Cache);

sub quit {
    exit if $OurNet::BBS::DEBUG;
}

sub invoke {
    my $obj    = ${$_[0]};
    my $parent = $_[2];
    my ($op, $param, @ret);

    @_[2, 3] = ([@_[3..$#_]], $_[2]); $#_ = 3;

    while ($_[-1]) {
	@_[$#_ .. $#_ + 2] = @OPTREE[$_[-1] .. $_[-1] + 2];
    }

    foreach my $i (2 .. (scalar @_ / 2)) {
	my ($op, $param) = @_[
	    ($#_ - ($i * 2)) + 2,
	    ($#_ - ($i * 2)) + 3,
	];

	my $checkop;

	if ($Auth->{mode} and not $Perm{"$obj $op"}
			  and substr(ref($obj), 0, 11) eq 'OurNet::BBS') {
	    if ($checkop = $OPREV->{$op}) {
		$op = $OP->{$op};
	    }
	    else {
		$checkop = substr($op, index($op, '_') + 1);
	    }

	    if ($checkop ne 'DESTROY') {
		return (
		    '', $OP->{STATUS_FORBIDDEN}, $checkop, 'not permitted'
		) unless ($checkop eq 'STORE' or $checkop eq 'DELETE')
		    ? $obj->writeok($Auth->{user}, $checkop, $param)
		    : $obj->readok($Auth->{user}, $checkop, $param);
	    }

	    $Perm{"$obj $op"} = 1;
	}
	else {
	    $op = $OP->{$op} || $op;
	}

        if ($op =~ m/^OBJECT\.(.+)/) {
            my @ret = $obj->$1(@{$param});
            return @ret unless $#ret == 0;
            $obj = $ret[0];
	    next;
	}

        my $arg = $param->[0] if @{$param};

        if ($op eq 'HASH_FETCH') {
	    return delete($Cache{$obj}{$arg}) 
		if exists $Cache{$obj}{$arg};

	    $obj = $obj->{$arg};
        } elsif ($op eq 'HASH_FIRSTKEY') {
	    if (UNIVERSAL::can($obj, 'ego')) {
		@ret = $obj->ego()->FIRSTKEY();
	    }
	    else {
		scalar keys(%$obj);
		@ret = each(%$obj);
	    }
	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return @ret;
        } elsif ($op eq 'HASH_NEXTKEY') {
	    if (UNIVERSAL::can($obj, 'ego')) {
		@ret = $obj->ego()->NEXTKEY();
	    }
	    else {
		@ret = each(%$obj);
	    }
	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return @ret;
	} elsif ($op eq 'HASH_DESTROY') {
            return;
        } elsif ($op eq 'ARRAY_DESTROY') {
            return;
        } elsif ($op eq 'HASH_FETCHARRAY') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY_FETCH') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY_FETCHSIZE') {
            return $#{$obj} + 1;
        } elsif ($op eq 'ARRAY_DEREFERENCE') {
            return @{$obj};
        } elsif ($op eq 'HASH_DEREFERENCE') {
            return %{$obj};
        } elsif ($op eq 'ARRAY_STORE') {
            return ($obj->[$arg] = $param->[1]);
        } elsif ($op eq 'HASH_STORE') {
	    return ($obj->{$arg} = $param->[1]);
        } elsif ($op eq 'ARRAY_DELETE') {
            return (delete $obj->[$arg]);
        } elsif ($op eq 'HASH_DELETE') {
            return (delete $obj->{$arg});
        } elsif ($op eq 'ARRAY_PUSH') {
            return (push @{$obj->{$arg}}, @{$param}[1..$#{$param}]);
        } elsif ($op eq 'ARRAY_POP') {
            $obj = pop(@{$obj->{$arg}});
        } elsif ($op eq 'ARRAY_SHIFT') {
            $obj = shift(@{$obj->{$arg}});
        } elsif ($op eq 'HASH_EXISTS') {
            return exists ($obj->{$arg});
        } elsif ($op eq 'ARRAY_EXISTS') {
            return exists ($obj->[$arg]);
        } elsif ($op eq 'ARRAY_UNSHIFT') {
            return (unshift @{$obj->{$arg}}, @{$param}[1..$#{$param}]);
        } else {
            warn "Unknown OP: $op (@{$param})\n";
        }
    }

    if (UNIVERSAL::isa($obj, 'UNIVERSAL')) { # is it an object?
	push @OPTREE, $_[1], $_[2], $parent;
	return ('', $OP->{OBJECT_SPAWN}, scalar $obj, $#OPTREE - 2);
    }
    else {
	return ($obj);
    }
}

1;


