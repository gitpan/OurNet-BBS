package OurNet::BBS::PlServer;

use strict;
use RPC::PlServer;
use base qw/RPC::PlServer/;
use vars qw/$ROOT/;

$OurNet::BBS::PlServer::VERSION = '0.1';

sub daemonize {
    my $self = shift;
    $ROOT = shift;

    # Server options below can be overwritten in the config file or
    # on the command line.
    my $server = __PACKAGE__->new({
        pidfile     => 'none',
        facility    => 'daemon', # Default
        methods     => {
            'OurNet::BBS::PlServer' => {
                NewHandle	=> 1,
                CallMethod	=> 1,
                DestroyHandle	=> 1,
                spawn		=> 1,
                invoke		=> 1,
                rootref		=> 1,
            },
        },    
	maxmessage  => ( 1 << 31 ),
        localport   => shift || 7978,
        mode        => 'fork',   # Recommended for Unix
#	compression => 'gzip',
    });
# , [ '--maxmessage' => 1048576 ] );

    $server->Bind();
}

sub spawn {
    return (bless(\$ROOT, $_[0]));
}

sub rootref {
    return ref($ROOT);
}

my (%Cache);

sub invoke {
    my $self = shift;
    my $obj = $$self;
    my @ret;

    # print "Traverse: \n";

    while (my $op = shift) {
        my $param = shift;

        # print "# traversing: $obj->$op(@$param)\n";

        if ($op =~ m/^OBJECT\.(.+)/) {
            my @ret = $obj->$1(@{$param});
            return @ret unless $#ret == 0;
            $obj = $ret[0];
	    next;
	}

        my $arg = shift(@{$param}) if @{$param};

        if ($op eq 'HASH.FETCH') {
	    return delete($Cache{$obj}{$arg}) 
		if exists $Cache{$obj}{$arg};

	    $obj = $obj->{$arg};
        } elsif ($op eq 'HASH.FIRSTKEY') {
	    if (UNIVERSAL::can($obj, 'ego')) {
		@ret = $obj->ego()->FIRSTKEY();
	    }
	    else {
		scalar keys(%$obj);
		@ret = each(%$obj);
	    }
	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return @ret;
        } elsif ($op eq 'HASH.NEXTKEY') {
	    if (UNIVERSAL::can($obj, 'ego')) {
		@ret = $obj->ego()->NEXTKEY();
	    }
	    else {
		@ret = each(%$obj);
	    }
	    $Cache{$obj}{$ret[0]} = $ret[1] if defined $ret[0];
	    return @ret;
	} elsif ($op eq 'HASH.DESTROY') {
            return;
        } elsif ($op eq 'ARRAY.DESTROY') {
            return;
        } elsif ($op eq 'HASH.FETCHARRAY') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY.FETCH') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY.FETCHSIZE') {
            return $#{$obj} + 1;
        } elsif ($op eq 'ARRAY.DEREFERENCE') {
            return @{$obj};
        } elsif ($op eq 'HASH.DEREFERENCE') {
            return %{$obj};
        } elsif ($op eq 'ARRAY.STORE') {
            return ($obj->[$arg] = $param->[0]);
        } elsif ($op eq 'HASH.STORE') {
	    return ($obj->{$arg} = $param->[0]);
        } elsif ($op eq 'ARRAY.DELETE') {
            return (delete $obj->[$arg]);
        } elsif ($op eq 'HASH.DELETE') {
            return (delete $obj->{$arg});
        } elsif ($op eq 'ARRAY.PUSH') {
            return (push @{$obj->{$arg}}, @{$param});
        } elsif ($op eq 'ARRAY.POP') {
            $obj = pop(@{$obj->{$arg}});
        } elsif ($op eq 'ARRAY.SHIFT') {
            $obj = shift(@{$obj->{$arg}});
        } elsif ($op eq 'HASH.EXISTS') {
            return exists ($obj->{$arg});
        } elsif ($op eq 'ARRAY.EXISTS') {
            return exists ($obj->[$arg]);
        } elsif ($op eq 'ARRAY.UNSHIFT') {
            return (unshift @{$obj->{$arg}}, @{$param});
        } else {
            warn "Unknown OP: $op ($arg @_)\n";
        }
    }

    return (UNIVERSAL::isa($obj, 'UNIVERSAL')) # is it an object?
	? ('OBJECT.SPAWN', scalar $obj) 
	: $obj;
}

1;
