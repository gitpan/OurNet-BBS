#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/6-MailBox.t $ $Author: autrijus $
# $Revision: #5 $ $Change: 2090 $ $DateTime: 2001/10/16 06:42:02 $

use strict;
use Test::More tests => 3;

require_ok('OurNet::BBS');
my $BBS = OurNet::BBS->new(MailBox => '.');
isa_ok($BBS, 'OurNet::BBS');
is(ref($BBS), $BBS->module('BBS'), 'constructor');

__END__
