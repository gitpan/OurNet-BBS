# $File: //depot/OurNet-BBS/BBS/Base.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1132 $ $DateTime: 2001/06/14 16:34:13 $

package OurNet::BBS::DBI::Board;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh board recno mtime _cache/;

BEGIN {
    __PACKAGE__->initvars(
        'BoardGroup' => [qw/@packlist/],
    );
}

sub refresh_articles {
    my $self = shift;

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new({
        dbh   => $self->{dbh},
        board => $self->{board},
        name  => 'articles',
    });
}

sub refresh_archives {
    my $self = shift;

    return $self->{_cache}{archives} ||= $self->module('ArticleGroup')->new({
        dbh   => $self->{dbh},
        board => $self->{board},
        name  => 'archives',
    });
}

sub refresh_meta {
    my ($self, $key) = @_;
    
    return if $key and !$self->contains($key);
    return if $self->timestamp(-1);

    # XXX: RETRIEVE ACCORDING TO @packlist
    @{$self->{_cache}}{@packlist} = () if 0;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    return if $key and !$self->contains($key);
    return if $self->timestamp(-1);

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;
    
    # XXX: STORE INTO @packlist
    $self->timestamp(1);

    return 1;
}

sub remove {
    my $self = shift;

    # XXX: DELETE BOARD ENTRY
    return 1;
}

1;

