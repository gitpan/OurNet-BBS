#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/8-OurNet-CVIC.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 1566 $ $DateTime: 2001/08/26 04:56:05 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 0 );

mkpath(["$prefix/boards", "$prefix/group", "$prefix/man/boards"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BOARDS") 
    or die "Cannot make $prefix/.BOARDS: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;

our $BBS = [CVIC => $prefix];
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
