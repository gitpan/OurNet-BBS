# $File: //depot/OurNet-BBS/BBS/SocketScalar.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1527 $ $DateTime: 2001/08/17 22:51:34 $

package OurNet::BBS::SocketScalar;

use IO::Socket::INET; # XXX Unix Socket: not yet.
use strict;

sub TIESCALAR {
    my ($class, $host, $port) = @_;
    $host .= ":$port" if $port;

    my $obj = IO::Socket::INET->new(PeerAddr => $host);
    print "connected: $host\n" if $OurNet::BBS::DEBUG;
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
