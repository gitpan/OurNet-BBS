#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/6-MailBox.t $ $Author: autrijus $
# $Revision: #6 $ $Change: 2993 $ $DateTime: 2002/02/04 13:55:33 $

use strict;
use Test::More tests => 3;

require_ok('OurNet::BBS');
my $BBS = OurNet::BBS->new({
    backend => 'MailBox',
    bbsroot => '.'
});

isa_ok($BBS, 'OurNet::BBS');
is(ref($BBS), $BBS->module('BBS'), 'constructor');

__END__
