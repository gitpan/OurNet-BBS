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

    # XXX: GENERATE ID
    return ($id = scalar time);
}

sub refresh_body {
    my $self = shift;
    return if $self->{_cache}{body};
    $self->{nntp}->group($self->{groupname});
    $self->{_cache}{body} = join('',@{$self->{nntp}->body($self->{recno})});
    return 1;
}

sub refresh_header {
    my $self = shift;
    return if $self->{head};
    $self->{nntp}->group($self->{groupname});
    $self->{head} = $self->{nntp}->head($self->{recno});
    foreach my $line (@{$self->{head}}) {
	chomp $line;
	my ($name, $value) = $line =~ m/([\w-]+):\s([\x00-\xff]*)/;
	$self->{_cache}{header}{$name} = $value;
    }
    return 1;
}

sub refresh_meta {
=head1
    my $self = shift;

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1);

    if (defined $self->{recno}) {
        # XXX: FETCH ONE ARTICLE HEADER
        # @{$self->{_cache}}{@packlist} = () if 0;
        undef $self->{recno}
            if ($self->{_cache}{id} and $self->{_cache}{id} ne $self->{name});
    }

    unless (defined $self->{recno}) {
        use Date::Parse;
        use Date::Format;

        $self->{_cache}{id}       = $self->{name};
        $self->{_cache}{author}   ||= 'guest.';
        $self->{_cache}{date}     ||= time2str('%y/%m/%d', str2time(scalar localtime));
        $self->{_cache}{title}    ||= '(untitled)';

        # XXX: STORE INTO ARTICLE
    }
    else {
        $self->{_cache}{id}       = $self->{name};
    }
=cut
    return 1;
}

sub STORE {
    die 'no Article STORE yet';
}

1;

