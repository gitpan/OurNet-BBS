package OurNet::BBS::DBI::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh board name dir recno mtime btime _cache/;

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

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1, 'btime')
              and defined $self->{_cache}{body};

    # XXX: FETCH BODY
    $self->{_cache}{body} = '' if 0;
    
    return 1;
}

sub refresh_header {
    my $self = shift;

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1)
              and defined $self->{_cache}{header};

    $self->refresh_meta();

    # XXX: FETCH HEADER
    my ($from, $date);

    $self->{_cache}{header} = {
        From         => $from  ||= (
            $self->{_cache}{author} .
            ($self->{_cache}{nick} ? " ($self->{_cache}{nick})" : '')
        ),
        Subject      => $self->{_cache}{title},
        Date         => $date ||= scalar localtime($self->{btime}),
        'Message-ID' => OurNet::BBS::Utils::get_msgid(
            $date,
            $from,
            $self->{board},
        ),
    };
    
    return 1;
}

sub refresh_meta {
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

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);

    if ($key eq 'body') {
        # XXX: WRITE BODY
        $self->{_cache}{$key} = $value;
        $self->{btime} = 1;
    }
    else {
        $self->{_cache}{$key} = $value;
        $self->{mtime} = 1;
    }
}

sub remove {
    my $self = shift;

    # XXX: DELETE ARTICLE ENTRY
    return 1;
}

1;

