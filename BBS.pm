# $File: //depot/OurNet-BBS/BBS.pm $ $Author: autrijus $
# $Revision: #41 $ $Change: 2088 $ $DateTime: 2001/10/16 05:33:05 $
# See BBS.pod for documentations.

package OurNet::BBS;
use 5.006;

$OurNet::BBS::VERSION  = '1.62_01';

use strict;
use warnings;
use OurNet::BBS::Utils;
use OurNet::BBS::Base (
    # the default fields for Maple2- and Maple3- derived BBS systems
    '@BOARDS'   => [qw/bbsroot brdshmkey maxboard/],
    '@FILES'    => [qw/bbsroot/],
    '@GROUPS'   => [qw/bbsroot/],
    '@SESSIONS' => [qw/bbsroot sessionshmkey maxsession chatport passwd/],
    '@USERS'    => [qw/bbsroot usershmkey maxuser/],
);

no strict 'refs';
my $sub_new = *{'new'}{CODE};

{
    no warnings qw/redefine/;

    sub new { 
	goto &{$sub_new} unless $_[0] eq __PACKAGE__;

	return $_[0]->fillmod(
	    (ref($_[1]) ? $_[1]->{backend} : $_[1]),  'BBS'
	)->new(@_[1 .. $#_])
    }           
}

# default permission settings
use constant readok  => 1;
use constant writeok => 0;

sub refresh_meta {
    my ($self, $key) = @_;

    return $self->fillin(
	$key, substr(ucfirst($key), 0, -1).'Group', 
	map { $self->{$_} } @{uc($key)}
    );
}

1;
