package OurNet::BBS::DBI::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/dbh board name dir recno mtime btime _cache _phash/;

# btime: header, mtime: directory

BEGIN {
    __PACKAGE__->initvars(
        '@packlist'   => [qw/id author nick date title/],
    );
}

sub new_id {
    my ($self, $id) = @_;

    # XXX: GENERATE ID
    return ($id = scalar time);
}

sub refresh_id {
    my ($self, $key) = @_;

    $self->{name} ||= $self->new_id();
    return if $self->timestamp(-1, 'btime');

    if (defined $self->{recno}) {
        # XXX: FETCH ONE ARTICLEGROUP-AS-ARTICLE HEADER
        @{$self->{_cache}}{@packlist} = () if 0;

        undef $self->{recno}
            if ($self->{_cache}{id} and 
                $self->{_cache}{id} ne $self->{name});
    }

    unless (defined $self->{recno}) {
        use Date::Parse;
        use Date::Format;

        $self->{_cache}{id}     = $self->{name};
        $self->{_cache}{author} ||= 'guest.';
        $self->{_cache}{date}   ||= time2str('%y/%m/%d', str2time(scalar localtime));
        $self->{_cache}{title}  ||= '(untitled)';

        # XXX: STORE INTO ARTICLEGROUP-AS-ARTICLE
    }

    return 1;
}

sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;

    if ($self->contains($key)) {
        goto &refresh_id; # metadata refresh
    }
    elsif (!defined($key) and $self->{dir}) {
        $self->refresh_id; # group-as-article refresh
    }

    if ($arrayfetch) {
        # XXX: ARRAY FETCH
        my $recno = $key;
        my $obj;

        die "$recno out of range" if $recno < 1; # || $recno > $max;
        return if $self->{_phash}[0][$recno]; # MUST DELETE THIS LINE

        # TRY GET $key
        $self->{_phash}[0][0]{$key} = $recno;
        $self->{_phash}[0][$recno] = $obj;
    }
    elsif ($key) {
        # XXX: KEY FETCH
        return if $self->{_phash}[0][0]{$key};

        my $obj; # TRY GET $obj

        # $self->{_phash}[0][0]{$key} = $obj->recno+1;
        # $self->{_phash}[0][$obj->recno+1] = $obj;

        return 1;        
    }
    else {
        # XXX: GLOBAL FETCH
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($self->contains($key)) {
        $self->refresh($key);
        $self->{_cache}{$key} = $value;

        # XXX STORE INTO ARTICLEGROUP-AS-ARTICLE
        $self->timestamp(1, 'btime');
    }
    else {
        my $obj;

        if ($key > 0 and exists $self->{_phash}[0][$key]) {
            $obj = $self->{_phash}[0][$key];
        }
        else {
            # new one if unspecified
            $key ||= $#{$self->{_phash}[0]} + 1;

            # XXX: DO ACTUAL STORAGE
            $obj = $self->module('Article', $value)->new({
                dbh   => $self->{dbh},
                board => $self->{board},
                dir   => $self->{dir},
#                recno => $key - 1,
            });
            
            $obj->refresh('id');
            
            # XXX: REMOVE IF NECCESSARY
            $self->{_phash}[0][$key] = $obj;
            $self->{_phash}[0][0]{$obj->name} = $key;
        }

        while (my ($k, $v) = each %{$value}) {
            $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };
        
        # delayed storage of body
        $obj->{body} = $value->{body} if exists $value->{body};

        $self->refresh($key, 1); # XXX: ASSUME ARRAY
        $self->timestamp(1);
    }
}

sub EXISTS {
    my ($self, $key) = @_;

    # XXX: EXISTS
    return 1 if exists ($self->{_cache}{$key});
}

1;
