package OurNet::BBS::BBSAgent::BoardGroup;
$VERSION = "0.1";

# BBSAgent support is still considered experimental. please report bugs.

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot login bbsobj mtime _cache/;
use OurNet::BBSAgent;

BEGIN {
    __PACKAGE__->initvars(
        '$Timeout' => 10,
    )
}

# Run sanity test. 
# if $nologin, no actual login will be attempted.
sub sanity_test {
    my ($self, $nologin) = @_;

	my $ego = tied(%{$self})
        ? UNIVERSAL::isa(tied(%{$self}), 'OurNet::BBS::ArrayProxy')
            ? tied(%{tied(%{$self})->{_hash}})
            : tied(%{$self})
        : $self;

	my $vars = ($ego->load_bbsobj('', $nologin) || return)->{var};
	my $brd = $vars->{sanity_board} or return 1;

    my %var = map {
        (substr($_, length("sanity_board_")), $vars->{$_})
    } grep {
        m/^sanity_board_/
    } keys(%{$vars}); # gets sanity_board_* variables

    my $rec = delete($var{rec}) || 1;
	print "Sanity testing: board $brd, rec $rec\n" if $OurNet::BBS::DEBUG;
    my $art = $self->{$brd}{articles}[$rec] or return;

    while (my ($k, $v) = each %var) {
		print "Asserting $k = $v\n" if $OurNet::BBS::DEBUG;
        next unless exists $art->{$k};
        return unless index($art->{$k}, $v) > -1; 
    }

	print "Sanity test passed.\n" if $OurNet::BBS::DEBUG;
    
    return 1;
}

sub load_bbsobj {
    my ($self, $bbsname, $nologin) = @_;

    return $self->{bbsobj} if $self->{bbsobj};

    $bbsname ||= $self->{bbsroot};
    $bbsname .= ".bbs" unless $bbsname =~ /\.bbs$/;

    # XXX hack, fixme
	my $bbsobj = OurNet::BBSAgent->new(OurNet::BBS::Utils::locate(
	    $bbsname,
    ) || OurNet::BBS::Utils::locate(
        "../../BBSAgent/$bbsname",
    ), $Timeout);

	print "$bbsname loaded\n" if $OurNet::BBS::DEBUG;
	return $bbsobj if $nologin;

    $self->{bbsobj} = $bbsobj;
    $self->{bbsobj}{debug} = $OurNet::BBS::DEBUG;
    
    if ($self->{login}) {
		eval {
			$self->{bbsobj}->login(split(/[:,]/, $self->{login}, 2));
		};
        $self->{bbsobj}{var}{username} ||= (
            split(/[:,]/, $self->{login}, 2)
        )[0];
    } else {
        eval {
			$self->{bbsobj}->login('guest');
		};
        $self->{bbsobj}{var}{username} ||= 'guest';
    }

	return $@ ? undef : $self->{bbsobj};
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    $self->load_bbsobj() or die "login failed: $self->{bbsobj}{errmsg}";

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new(
            $self->{bbsobj},
            $key
        );
        return;
    }

    die 'board listing not implemented';
}

sub EXISTS {
    die 'board listing not implemented';
}

sub STORE {
    die 'board listing not implemented';
}

1;
