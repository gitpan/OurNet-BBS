# $File: //depot/OurNet-BBS/BBS/SocketScalar.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::SocketScalar;

use IO::Socket::INET; # XXX Unix Socket: not yet.
use strict;

sub TIESCALAR {
    my ($class, $host, $port) = @_;
    $host .= ":$port" if $port;

    my $obj = IO::Socket::INET->new(PeerAddr => $host);
    print "connected: $host\n";
    my $self = bless(\$obj, $class);
    return $self;
}

sub FETCH {
    my $self = shift;
    my ($msg, $buf);

    while (${$self}->read($buf, 1)) {
        last if $buf eq "\x00"; # XXX only works for chatroom
        $msg .= $buf;
    }

    return $msg;
}

sub STORE {
    my $self = shift;
    ${$self}->send(@_);
}

1;
