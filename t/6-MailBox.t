#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/6-MailBox.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 1562 $ $DateTime: 2001/08/26 03:16:24 $

use strict;
use Test::More tests => 1;
use OurNet::BBS;

my $BBS = OurNet::BBS->new(MailBox => '.');
is(ref($BBS), $BBS->module('BBS'), 'constructor');

__END__
