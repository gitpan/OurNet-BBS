package OurNet::BBS::NNTP::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/nntp groupname head recno _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'ArticleGroup' => [qw/@packlist/],
    );
}

sub new_id {
    my ($self, $id) = @_;

    return ($id = scalar time);
}

sub refresh_body {
    my $self = shift;

    return if $self->{_cache}{body};

    $self->{nntp}->group($self->{groupname});
    $self->{_cache}{body} = join('', @{$self->{nntp}->body($self->{recno})});

    return 1;
}

sub refresh_header {
    my $self = shift;

    return if $self->{head};

    $self->{nntp}->group($self->{groupname});
    $self->{head} = $self->{nntp}->head($self->{recno});

    foreach my $line (@{$self->{head}}) {
	next unless $line =~ m/([\w-]+):\s(.*)/;
	print "(set header $1 to $2)\n" if $OurNet::BBS::DEBUG;
	$self->{_cache}{header}{$1} = $2;
    }
    return 1;
}

sub refresh_meta {
    return 1;
}

sub STORE {
    die 'no Article STORE yet';
}

1;

