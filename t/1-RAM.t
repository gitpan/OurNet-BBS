#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/1-RAM.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 1662 $ $DateTime: 2001/09/02 05:54:09 $

use strict;
use OurNet::BBS;
our $BBS = OurNet::BBS->new('RAM');
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
