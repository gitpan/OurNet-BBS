package OurNet::BBS::Base;

$VERSION = '0.1';

use strict;
use OurNet::BBS::ArrayProxy;

# These magical hashes below holds all cached initvar constants:
# = subrountines   as $RegSub{$glob}
# = module imports as $RegMod{$glob}
# = variables      as $RegVar{$class}{$sym}

use vars qw/%RegVar %RegSub %RegMod/; 

sub initvars {
    my $class = shift;

    local $^W;
    no strict 'refs';

    if (!UNIVERSAL::can($class, '__accessor')) {
        foreach my $property (keys(%{$class."::FIELDS"}), '__accessor') {
            *{"${class}::$property"} = sub {
                my $self = $_[0]->ego();

                $self->refresh();
                $self->{$property} = $_[1] if $#_ > 0;
                return $self->{$property};
            };
        }
    }

    my $backend = $1 if scalar caller() =~ m|^OurNet::BBS::([^:]+)|;

    my @defer;

    foreach my $parent (@{"${class}::ISA"}) {
        next if $parent eq __PACKAGE__;

        while (my ($sym, $ref) = each(%{"${parent}::"})) {
	    push @defer, $class, $sym, $ref;
        }

	unshift @_, @{$RegMod{$parent}}
	    if ($RegMod{$parent});
    }

    while (my ($mod, $symref) = splice(@_, 0, 2)) {
        if ($mod =~ m/^\w/) { # getvar from other modules

	    push @{$RegMod{$class}}, $mod, $symref;

            require "OurNet/BBS/$backend/$mod.pm";
            $mod = "OurNet::BBS::${backend}::${mod}";

            foreach my $symref (@{$symref}) {
                my ($ch, $sym) = unpack('a1a*', $symref);
		next unless *{"${mod}::$sym"};

		++$RegVar{$class}{$sym};

                *{"${class}::$sym"} = (
                    $ch eq "\$" ? \$ {"${mod}::$sym"} :
                    $ch eq "\@" ? \@ {"${mod}::$sym"} :
                    $ch eq "\%" ? \% {"${mod}::$sym"} :
                    $ch eq "\*" ? \* {"${mod}::$sym"} :
                    $ch eq "\&" ? \& {"${mod}::$sym"} : ''
                );
            }
        }
        else { # setvar to this module
            my ($ch, $sym) = unpack('a1a*', $mod);

	    *{"${class}::$sym"} = ($ch eq '$') ? \$symref : $symref;
	    ++$RegVar{$class}{$sym};
        }
    }

    my @defer_sub;
    while (my ($class, $sym, $ref) = splice(@defer, 0, 3)) {
	next if exists $RegVar{$class}{$sym}  # already imported
	     or defined(*{"${class}::$sym"}); # defined by use subs

	if (defined(&{$ref})) { 
	    push (@defer_sub, $class, $sym, $ref);
	    next; 
	}

	next unless ($ref =~ /^\*(.+)::(.+)/)
	        and exists $RegVar{$1}{$2};

	*{"${class}::$sym"} = $ref;
	++$RegVar{$class}{$sym};
    } 

    while (my ($class, $sym, $ref) = splice(@defer_sub, 0, 3)) {
	my $ref = ($RegSub{$ref} || $ref);
	next unless ($ref =~ /^\*(.+)::([^_][^:]+)$/);

	if (%{$RegVar{$class}}) {
	    eval qq(
		*{"${class}::$sym"} = sub {
	    ) . join('', 
		map { qq(
		    local *$1::$_ = *${class}::$_;
		)} (keys(%{$RegVar{$class}}))
	    ) . qq(
		    &{$ref}(\@_);
		};
	    );
	}
	else {
	    *{"${class}::$sym"} = $ref;
	};

	$RegSub{"*${class}::$sym"} = $ref;
    }
}

sub ego {
    my $self = $_[0];

    return (
	tied(%{$self})
            ? UNIVERSAL::isa(tied(%{$self}), "OurNet::BBS::ArrayProxy")
                ? tied(%{tied(%{$self})->{_hash}})
                : tied(%{$self})
            : $self
    );
}

sub daemonize {
    require OurNet::BBS::Server;
    OurNet::BBS::Server->daemonize(@_);
}

sub writeok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

sub readok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

sub new {
    my $class = shift;
    my ($self, $proxy);

    no strict 'refs';

    tie %{$self}, $class, @_;
    tie @{$proxy}, 'OurNet::BBS::ArrayProxy', $self
	if (exists(${"$class\::FIELDS"}{_phash}));

    return bless($proxy || $self, $class);
}

sub STORE {
    die "@_: STORE unimplemented";
}

sub DELETE {
    my ($self, $key) = @_;

    $self->refresh($key);
    return unless exists $self->{_cache}{$key};

    $self->{_cache}{$key}->ego()->remove()
	or die "can't DELETE $key: $!";

    return delete($self->{_cache}{$key});
}

sub purge {
    my $self = $_[0]->ego();

    if (exists $self->{_cache}) {
	$self->{_cache} = {};
    }

    if (exists $self->{_phash}) {
	$self->{_phash}[0] = [ {} ];
    }
}

sub DESTROY {};
sub CLEAR {};

# Base Tiehash
sub TIEHASH {
    no strict 'refs';

    my $class = $_[0];
    my $self  = bless ([\%{"$class\::FIELDS"}], $class); # performance cruft

    if (UNIVERSAL::isa($_[1], 'HASH')) {
        # Passed in a single hashref -- assign it!
	%{$self} = %{$_[1]};
    }
    else {
        # Automagically fill in the fields.
        foreach my $key (keys(%{$self})) {
            $self->{$key} = $_[$self->[0]{$key}];
        }
    }

    return $self;
}

sub FETCH {
    my ($self, $key) = @_;

    if (exists($self->{_phash})) {
        ${$self->{_phash}[1]} = $key;
        return 1;
    }
    else {
        $self->refresh($key);
        return $self->{_cache}{$key};
    }
}

sub EXISTS {
    my ($self, $key) = @_;

    $self->refresh($key);

    return (exists $self->{_cache}{$key} or
           (exists $self->{_phash} and
            exists $self->{_phash}[0]{$key})) ? 1 : 0;
}

sub FIRSTKEY {
    my $self = $_[0];

    $self->refresh_meta();

    scalar (
	(exists $self->{_phash})
	    ? keys (%{$self->{_phash}[0]})
	    : keys (%{$self->{_cache}})
    );

    return $self->NEXTKEY();
}

sub NEXTKEY {
    my $self = $_[0];

    if (exists $self->{_phash}) {
	return (each %{$self->{_phash}[0]});
    }
    else {
	return (each %{$self->{_cache}});
    }
}

sub refresh {
    my ($self, $key, $arrayfetch) = @_;

    $self = $self->ego();

    my $method = 'refresh_' .
	($key && $self->can("refresh_$key") ? $key : 'meta');

    return $self->$method($key, $arrayfetch);
}

sub backend {
    my $self = $_[0]->ego();

    my $backend = ref($self);
    $backend = $1 if $backend =~ m|^OurNet::BBS::(\w+)|;

    return $backend;
}

sub module {
    my ($self, $mod, $val) = @_;

    if ($val) {
        # Store value
        die "STORE: attempt to store non-hash value ($val) into ".ref($self)
            unless UNIVERSAL::isa($val, 'HASH');

        return ref($val) if (UNIVERSAL::isa($val, 'UNIVERSAL'));
    }

    my $backend = $self->backend();

    require "OurNet/BBS/$backend/$mod.pm";
    return "OurNet::BBS::${backend}::${mod}";
}

sub timestamp {
    my ($self, $time, $field) = @_;
    
    if ($self->{$field || 'mtime'} and
        $self->{$field || 'mtime'} == $time) {
        return 1; # nothing changed
    }
    else {
        $self->{$field || 'mtime'} = $time;
        return 0; # something changed
    }
}

my %Packlists;

# every package contains undef
sub contains {
    my ($self, $key) = @_;
    no strict 'refs';

    return unless defined $key;
    return (index(
        $Packlists{ref($self)} ||= 
	    (' '.join(' ', @{ref($self)."::packlist"}).' '),
        " $key ",
    ) > -1);
}

# loads a module: ($self, $backend, $module).
sub fillmod {
    my $self = $_[0];
    $self =~ s|::|/|g;
    
    require "$self/$_[1]/$_[2].pm";
    return join('::', @_);
}

sub fillin {
    my ($self, $key, $class) = splice(@_, 0, 3);
    return if defined($self->{_cache}{$key});

    $self->{_cache}{$key} = OurNet::BBS->fillmod(
	$self->{backend}, $class
    )->new(@_);

    return 1;
}

1;
