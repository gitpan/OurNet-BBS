#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/7-OurNet-RAM.t $ $Author: autrijus $
# $Revision: #3 $ $Change: 2993 $ $DateTime: 2002/02/04 13:55:33 $

use strict;
use OurNet::BBS;

our $BBS = { backend => 'RAM' };
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
