# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #22 $ $Change: 1290 $ $DateTime: 2001/06/25 20:46:35 $

package OurNet::BBS::Base;

use strict;
use OurNet::BBS::ArrayProxy;

# These magical hashes below holds all cached initvar constants:
# = subrountines   as $RegSub{$glob}
# = module imports as $RegMod{$glob}
# = variables      as $RegVar{$class}{$sym}

my (%RegVar, %RegSub, %RegMod); 

my %Packlists; # $packlist cache for contains()

## Class Methods ######################################################
# These methods expects a package name as their first argument.

# constructor method; turn into an pseudo hash if _phash exists
sub new {
    my $class = shift;
    my ($self, $proxy);

    no strict 'refs';

    tie %{$self}, $class, @_;
    tie @{$proxy}, 'OurNet::BBS::ArrayProxy', $self
	if (exists(${"$class\::FIELDS"}{_phash}));

    return bless($proxy || $self, $class);
}

# Class method; implements mutable variable inheritance across namespaces
sub initvars {
    my $class = shift;

    no strict 'refs';
    no warnings 'once';

    # install accessor methods
    unless (UNIVERSAL::can($class, '__accessor')) {
        foreach my $property (keys(%{"$class\::FIELDS"}), '__accessor') {
            *{"$class\::$property"} = sub {
                my $self = $_[0]->ego;

                $self->refresh;
                $self->{$property} = $_[1] if $#_;
                return $self->{$property};
            };
        }
    }

    my $backend = $1 if scalar caller() =~ m|^OurNet::BBS::([^:]+)|;

    my @defer; # delayed aliasing until variables are processed
    foreach my $parent (@{"$class\::ISA"}) {
        next if $parent eq __PACKAGE__; # Base won't use mutable variables

        while (my ($sym, $ref) = each(%{"$parent\::"})) {
	    push @defer, ($class, $sym, $ref);
        }

	unshift @_, @{$RegMod{$parent}} if ($RegMod{$parent});
    }

    while (my ($mod, $symref) = splice(@_, 0, 2)) {
        if ($mod =~ m/^\w/) { # getvar from other modules
	    push @{$RegMod{$class}}, $mod, $symref;

            require "OurNet/BBS/$backend/$mod.pm";
            $mod = "OurNet::BBS::$backend\::$mod";

            foreach my $symref (@{$symref}) {
                my ($ch, $sym) = unpack('a1a*', $symref);
		die "can't import: $mod\::$sym" unless *{"$mod\::$sym"};

		++$RegVar{$class}{$sym};

                *{"$class\::$sym"} = (
                    $ch eq '$' ? \${"$mod\::$sym"} :
                    $ch eq '@' ? \@{"$mod\::$sym"} :
                    $ch eq '%' ? \%{"$mod\::$sym"} :
                    $ch eq '*' ? \*{"$mod\::$sym"} :
                    $ch eq '&' ? \&{"$mod\::$sym"} : undef
                );
            }
        }
        else { # this module's own setvar
            my ($ch, $sym) = unpack('a1a*', $mod);

	    *{"$class\::$sym"} = ($ch eq '$') ? \$symref : $symref;
	    ++$RegVar{$class}{$sym};
        }
    }

    my @defer_sub; # further deferred subroutines that needs localizing
    while (my ($class, $sym, $ref) = splice(@defer, 0, 3)) {
	next if exists $RegVar{$class}{$sym} # already imported
	     or defined(*{"$class\::$sym"}); # defined by use subs

	if (defined(&{$ref})) { 
	    push @defer_sub, ($class, $sym, $ref);
	    next; 
	}

	next unless ($ref =~ /^\*(.+)::(.+)/)
	        and exists $RegVar{$1}{$2};

	*{"$class\::$sym"} = $ref;
	++$RegVar{$class}{$sym};
    } 

    # install per-package wrapper handlers for mutable variables
    while (my ($class, $sym, $ref) = splice(@defer_sub, 0, 3)) {
	my $ref = ($RegSub{$ref} || $ref);
	next unless ($ref =~ /^\*(.+)::([^_][^:]+)$/);

	if (%{$RegVar{$class}} and (uc($sym) ne $sym or $sym eq 'STORE')) {
	    eval qq(
		sub $class\::$sym {
	    ) . join('', 
		map { qq(
		    local *$1\::$_ = *$class\::$_;
		)} (keys(%{$RegVar{$class}}))
	    ) . qq(
		    &{$ref}(\@_);
		};
	    );
	}
	else {
	    *{"$class\::$sym"} = $ref;
	};

	$RegSub{"*$class\::$sym"} = $ref;
    }
}

## Instance Methods ###################################################
# These methods expects a tied object as their first argument.

# unties through an object to get back the true $self
sub ego {
    my $self = $_[0];

    return (
	tied(%{$self})
            ? UNIVERSAL::isa(tied(%{$self}), 'OurNet::BBS::ArrayProxy')
                ? tied(%{tied(%{$self})->{_hash}})
                : tied(%{$self})
            : $self
    );
}

# the all-important cache refresh instance method
sub refresh {
    my $self = (shift)->ego;
    my $method = (
	$_[0] && UNIVERSAL::can($self, "refresh_$_[0]")
    ) || 'refresh_meta';

    return $self->$method(@_);
}

# opens access to connections via OurNet protocol
sub daemonize {
    require OurNet::BBS::Server;
    OurNet::BBS::Server->daemonize(@_);
}

# permission checking; fall-back for undefined packages
sub writeok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

# ditto
sub readok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

# clears internal memory; uses CLEAR instead
sub purge {
    $_[0]->ego->CLEAR;
}

# the fallback implementation of per-object DELETE handler
sub remove {
    die "can't DELETE @_: $!";
}

# returns the BBS backend for the object
sub backend {
    my $self = $_[0]->ego;

    my $backend = ref($self);
    $backend = $1 if $backend =~ m|^OurNet::BBS::(\w+)|;

    return $backend;
}

# developer-friendly way to check timestamp for mtime fields
sub timestamp {
    no warnings qw/uninitialized numeric/;

    my ($self, $file, $field) = @_;
    my $time = int($file) ? $file : (stat($file))[9]; # XXX: too magical

    if ($self->{$field || 'mtime'} == $time) {
        return 1; # nothing changed
    }
    else {
        $self->{$field || 'mtime'} = $time unless defined $field;
        return 0; # something changed
    }
}

# check if something's in packlist; packages don't contain undef
sub contains {
    my ($self, $key) = @_;

    no strict 'refs';

    return (defined $key and index(
        $Packlists{ref($self)} ||= " @{ref($self).'::packlist'} ",
        " $key ",
    ) > -1);
}

# loads a module: ($self, $backend, $module).
sub fillmod {
    my $self = $_[0];
    $self =~ s|::|/|g;
    
    require "$self/$_[1]/$_[2].pm";
    return "$_[0]::$_[1]::$_[2]";
}

# create a new module and fills in arguments in the expected order
sub fillin {
    my ($self, $key, $class) = splice(@_, 0, 3);
    return if defined($self->{_cache}{$key});

    $self->{_cache}{$key} = OurNet::BBS->fillmod(
	$self->{backend}, $class
    )->new(@_);

    return 1;
}

# returns the module in the same backend, or $val's package if supplied
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
    return "OurNet::BBS::$backend\::$mod";
}

# object serialization for OurNet::Server calls; does nothing otherwise
sub SPAWN { return $_[0] }
sub REF { return ref($_[0]) }

## Tiehash Accessors ##################################################
# These methods expects a raw (untied) object as their first argument.

# the Tied Hash constructor method
sub TIEHASH {
    no strict 'refs';

    my $self  = bless([\%{"$_[0]\::FIELDS"}], $_[0]); # performance cruft

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

# fetch accessesor; will delegate via PHash magic to ArrayProxy if needed
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

# fallback implementation to STORE
sub STORE {
    die "@_: STORE unimplemented";
}

# delete an element; calls its remove() subroutine to handle actual removal
sub DELETE {
    my ($self, $key) = @_;

    $self->refresh($key);
    return unless exists $self->{_cache}{$key};

    $self->{_cache}{$key}->ego->remove;
    return delete($self->{_cache}{$key});
}

# check for existence of a key; will look into both _cache and _phash keys
sub EXISTS {
    my ($self, $key) = @_;

    $self->refresh($key);

    return (exists $self->{_cache}{$key} or
           (exists $self->{_phash} and
            exists $self->{_phash}[0]{$key})) ? 1 : 0;
}

# iterator; this one merely uses 'scalar keys()'
sub FIRSTKEY {
    my $self = $_[0];

    $self->refresh_meta;

    scalar (
	(exists $self->{_phash})
	    ? keys (%{$self->{_phash}[0]})
	    : keys (%{$self->{_cache}})
    );

    return $self->NEXTKEY;
}

# ditto
sub NEXTKEY {
    my $self = $_[0];

    if (exists $self->{_phash}) {
	return (each %{$self->{_phash}[0]});
    }
    else {
	return (each %{$self->{_cache}});
    }
}

# empties the cache, do not DELETE the objects themselves
sub CLEAR {
    my $self = $_[0];

    if (exists $self->{_cache}) {
	$self->{_cache} = {};
    }

    if (exists $self->{_phash}) {
	$self->{_phash}[0] = [ {} ];
    }
}

# couldn't care less
sub UNTIE {}
sub DESTROY {}

1;
