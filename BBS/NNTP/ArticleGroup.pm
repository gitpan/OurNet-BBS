package OurNet::BBS::NNTP::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/nntp board groupname first num last _cache _phash/;
use Date::Parse;
use Date::Format;
# FIXME: use first/last update to determine refresh result

BEGIN {
    __PACKAGE__->initvars(
        '@packlist'   => [qw//],
    );
}

sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;
    # for compatibility.
    $self->{board} ||= $self->{groupname};
    @{$self}{qw/num first last/} = $self->{nntp}->group($self->{groupname})
	unless $self->{groupname} eq $self->{nntp}->group();

    if ($arrayfetch) {
        # XXX: ARRAY FETCH
        die "$key out of range"
	    if $key < $self->{first} || $key > $self->{last};
	my $head = $self->{nntp}->head($key);
	die "no such article $key" unless defined $head;

        return if $self->{_phash}[0][$key]; # MUST DELETE THIS LINE

        my $obj = $self->module('Article')->new
	({
	  nntp		=> $self->{nntp},
	  groupname	=> $self->{groupname},
	  recno		=> $key
	 });
        $self->{_phash}[0][0]{$key} = $key;
        $self->{_phash}[0][$key] = $obj;
    }
    elsif ($key) {
	die 'no key fetch yet';
    }
    else {
        # XXX: GLOBAL FETCH
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    die "STORE non-hash ref" unless UNIVERSAL::isa($value, 'HASH');
    @{$self}{qw/first num last/} = $self->{nntp}->group($self->{groupname})
	unless $self->{groupname} eq $self->{nntp}->group();
    my %header = %{$value->{header}};
    $header{Date} = time2str('%d %b %Y %T %Z', str2time($header{Date}));
    delete $header{Board};
    $header{Newsgroups} ||= $self->{groupname};
    $header{'Message-ID'} =~ s/^([^<].*[^>])$/<$1>/;
    $self->{nntp}->post
#print "posting: ".join('', 
(((map {"$_: $header{$_}\n"}
			 (keys %header)), "\n",
			 $value->{body}));

print "post returns: ".$self->{nntp}->message;
return 1;
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

1;
