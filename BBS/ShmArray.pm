# $File: //depot/OurNet-BBS/BBS/ShmArray.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::ShmArray;
use strict;

# ($class, $shmid, $pos, $sz, $count, $packstr);
sub TIEARRAY {
    my $class = shift;

    return bless([@_], $class);
}

sub FETCH {
    my ($self, $key) = @_;
    my $buf;
    shmread($self->[0], $buf, $self->[1]+$self->[2]*$key, $self->[2]);
    return [unpack($self->[4], $buf)];
}

sub FETCHSIZE {
    $_[0]->[3];
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $buf = pack($self->[4], @{$value});
    shmwrite($self->[0], $buf, $self->[1]+$self->[2]*$key, $self->[2]);
}

1;
