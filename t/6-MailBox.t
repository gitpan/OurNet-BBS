#!/usr/bin/perl -w
# $File: //depot/OurNet-BBS/t/6-MailBox.t $ $Author: autrijus $
# $Revision: #3 $ $Change: 2069 $ $DateTime: 2001/10/15 08:02:05 $

use strict;
use Test::More tests => 3;

SKIP: {
    skip('Mail::Box not installed', 3) unless (eval "use Mail::Box; 1;");

    require_ok('OurNet::BBS');
    my $BBS = OurNet::BBS->new(MailBox => '.');
    isa_ok($BBS, 'OurNet::BBS');
    is(ref($BBS), $BBS->module('BBS'), 'constructor');
}

__END__
