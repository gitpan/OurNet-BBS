#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/4-MELIX.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 1562 $ $DateTime: 2001/08/26 03:16:24 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 1 );

mkpath(["$prefix/brd", "$prefix/gem", "$prefix/gem/@", "$prefix/gem/brd"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BRD")
    or die "Cannot make $prefix/.BRD: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;
our $BBS = OurNet::BBS->new(MELIX => $prefix);
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
