# $File: //depot/OurNet-BBS/BBS/ScalarFile.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1265 $ $DateTime: 2001/06/23 16:52:45 $

package OurNet::BBS::ScalarFile;

sub TIESCALAR {
    my ($class, $filename) = @_;
    my ($cache, $mtime) = (undef, 0);
    
    return bless([$filename, $mtime, $cache], $class);
}

sub FETCH {
    my $self = shift;
    my $filename = $self->[0];
    
    if (-e $filename) {
        return $self->[2] if ((stat($filename))[9] == $self->[1]); # cached
        $self->[1] = (stat($filename))[9];
        
        local $/;
        open FILE, $filename or die "cannot read $filename: $!";
        $self->[2] = <FILE>;
        close FILE;
        
        return $self->[2];
    }
    else {
        undef $self->[1]; # empties mtime
        undef $self->[2]; # empties cache
        return;
    }
}

sub STORE {
    my $self     = shift;
    my $filename = $self->[0];

    no warnings 'uninitialized';
    
    if (defined($_[0])) {
        if (length($self->[2]) and 
	    length($_[0]) >= length($self->[2]) and 
	    substr($_[0], 0, length($self->[2])) eq $self->[2]) 
        {
            # append mode
            open(my $FILE, '>>', $filename) 
		or die "cannot append $filename: $!";
            print $FILE substr($_[0], length($self->[2]));
            close $FILE;
        }
        else {
            open(my $FILE, '>', $filename) 
		or die "cannot write $filename: $!";
            print $FILE $_[0];
            close $FILE;
        }
        $self->[1] = (stat($filename))[9];
        $self->[2] = $_[0];
    }
    else {
        # store undef: kill the file
        undef $self->[1];
        unlink $filename or die "cannot delete $file: $!" if -e $filename;
    }

    return $self->[2];
}

1;
