#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/2-CVIC.t $ $Author: autrijus $
# $Revision: #3 $ $Change: 2993 $ $DateTime: 2002/02/04 13:55:33 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 1 );                              

mkpath(["$prefix/boards", "$prefix/group", "$prefix/man/boards"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BOARDS") 
    or die "Cannot make $prefix/.BOARDS: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;
our $BBS = OurNet::BBS->new({backend => 'CVIC', bbsroot => $prefix});
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
