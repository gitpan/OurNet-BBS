package OurNet::BBS::Authen;

use strict;

use IO::Handle;
use GnuPG::Interface;
use fields qw/gnupg who pass mode login keyid user cipher challenge/;
use vars qw/$OPREV $OP/;

my $i = 0;

$OP = {
    # STATUS Operators (the usual ones)
    (map { ("STATUS_$_" => $i++ ) }
        qw/OK ACCEPTED FORBIDDEN NO_PUBKEY BAD_PUBKEY BAD_SIGNATURE/),
    # HASH Operators            
    (map { ("HASH_$_" => $i++ ) }
        (qw/FETCH FIRSTKEY NEXTKEY DESTROY FETCHARRAY 
           DEREFERENCE STORE DELETE EXISTS/)),
    # ARRAY Operators           
    (map { ("ARRAY_$_" => $i++) }
        qw/FETCH DESTROY FETCHARRAY SHIFT UNSHIFT PUSH POP
           DEREFERENCE STORE DELETE EXISTS/),
    # OBJECT Operators (the usual ones)
    (map { ("OBJECT_$_" => $i++ ) }
        qw/SPAWN refresh refresh_meta board id backend remove contains/),
};

$OPREV = { 
    map { $OP->{$_} => substr($_, index($_, '_') + 1) } 
    keys %{$OP} 
};

$OP    = { %{$OP}, reverse %{$OP} };

# query for existing BCB ciphers
sub suites {
    my $self = shift if @_;
    my @ciphers = @_ ? @_ : map { "Crypt::$_" } (
	qw/Rijndael Twofish Blowfish DES Twofish2 
	   TEA GOST Blowfish_PP DES_PP/
    );

    my @suites;

    foreach my $cipher (@ciphers) {
	my $req = $cipher;
	$req =~ s|::|/|g;

	local $@; local $^W;
	eval { require "$req.pm" };
	next if $@;

	$self->{cipher} = $cipher if ref($self);
	return $cipher if @_;

	push @suites, $cipher;
    }

    warn "\n[Authen] cannot find a block cipher suite from:\n@_\n".
         "secure connection will be disabled.\n" unless @suites;

    return @suites;
}

sub test {
    my $self = shift;

    return $self->{gnupg}->test_default_key_passphrase();
}

sub new {
    my ($class, $who, $pass, $mode) = @_;
    my $self = fields::new($class);
    my $gpg  = $self->{gnupg} = GnuPG::Interface->new();

    $self->{who} = $who or die "need recipients";
    $self->{mode} = $mode;

    $gpg->options->hash_init(armor => 1, always_trust => 1);
    $gpg->options->meta_interactive(0);
    $gpg->options->push_recipients($who);
    $gpg->passphrase($self->{pass} = $pass) if defined $pass;

    return $self;
}

sub setpass {
    my ($self, $pass) = @_;

    $self->{gnupg}->passphrase($self->{pass} = $pass);
}

sub gpg_setup {
    my ( $input, $output, $stderr )
           = ( IO::Handle->new(),
               IO::Handle->new(),
               \*STDERR);

    my $handles = GnuPG::Handles->new( 
        stdin  => $input,
        stdout => $output,
        stderr => $stderr,
    );

    return ($input, $output, $stderr, $handles);
}

foreach my $method (
    qw/clearsign sign verify encrypt decrypt import_keys export_keys/
) {
    my $subname = $method;
    no strict 'refs';
    $subname =~ s/_keys/_key/;

    *{__PACKAGE__."::$subname"} = sub {
	my $self = shift;

	if ($method eq 'decrypt' and not defined $self->{pass}) {
	    print "error: no passphrase for $self->{who}.\n";
	    exit;
	}

	my ($i, $o, $e, $h) = gpg_setup();

	my $pid = $self->{gnupg}->$method( 
	    handles => $h,
	    command_args =>
		($method eq 'export_keys') ? (
		    $self->{keyid} || $self->{who},
		) : ($method eq 'clearsign') ? (
		    ['--default-key',  $self->{keyid}],
		) : ($method eq 'sign') ? (
		    ['--default-key',  $self->{keyid}],
		) : ( '' ),
	);

	if (@_) {
	    print $i @_;
	    close $i;
	}

	local $/;
	my $ret = ($method eq 'verify') ? <$e> : <$o>;  # reading the output
	waitpid $pid, 0;  # clean up the finished GnuPG process
	return $ret;
    };
}

1;

