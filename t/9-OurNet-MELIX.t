#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/9-OurNet-MELIX.t $ $Author: autrijus $
# $Revision: #5 $ $Change: 2993 $ $DateTime: 2002/02/04 13:55:33 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 0 );

mkpath(["$prefix/brd", "$prefix/gem", "$prefix/gem/@", "$prefix/gem/brd"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BRD") or die "Cannot make $prefix/.BRD: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;

our $BBS = { backend => 'MELIX', bbsroot => $prefix };
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
