# $File: //depot/OurNet-BBS/BBS/ArrayProxy.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1407 $ $DateTime: 2001/07/11 22:27:23 $

package OurNet::BBS::ArrayProxy;

sub FETCHSIZE {
    my $ego  = (tied %{$_[0]->{_hash}});

    return $ego->FETCHSIZE if ($ego->can('FETCHSIZE'));

    $ego->refresh;
    return (($#{$ego->{_phash}[0]} + 1) || 1);
}

sub TIEARRAY {
    my ($class, $hash, $flag) = @_;
    my $self = {_flag => \$flag, _hash => $hash};

    (tied %$hash)->{_phash}[1] = (\$flag);
    return bless($self, $class);
}

sub PUSH {
    my $self = shift;
    my $size = $self->FETCHSIZE;

    foreach my $item (@_) {
        $self->STORE($size++, $item);
    }
}

sub STORE {
    my ($self, $key) = splice(@_, 0, 2);
    my $ego  = (tied %{$self->{_hash}});

    $ego->STORE(
        (defined(${$self->{_flag}}) ? ${$self->{_flag}} : $key), @_
    );
}

sub DELETE {
    my ($self, $key) = splice(@_, 0, 2);
    my $ego  = (tied %{$self->{_hash}});

    $ego->DELETE(
        (defined(${$self->{_flag}}) ? ${$self->{_flag}} : $key), @_
    );
}

sub EXISTS {
    my ($self, $key) = @_;
    my $ego  = (tied %{$self->{_hash}});

    $ego->refresh($key, 1);
    return $ego->{_phash}[0][$key] ? 1 : 0;
}

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{_hash};
    return $hash if $key == 0;

    my $ego = tied %{$hash};

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

        $ego->refresh($key);
        return (exists $ego->{_phash}[0] and $ego->{_phash}[0][0]{$key})
            ? $ego->{_phash}[0]{$key}
            : $ego->{_cache}{$key};
    }
    else {
        $ego->refresh($key, 1);
        return $ego->{_phash}[0][$key];
    }
}

# couldn't care less
sub UNTIE {}
sub CLEAR {}
sub EXTEND {}
sub DESTROY {}

1;
