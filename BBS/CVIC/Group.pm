# $File: //depot/OurNet-BBS/BBS/CVIC/Group.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::CVIC::Group;

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot group mtime _cache/;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";
    my $board;

    return unless $self->{group};

    return if $self->{mtime} and (stat($file))[9] == $self->{mtime};

    my $GROUP;
    open($GROUP, $file) or open($GROUP, '+>>', $file)
        or die("Cannot read group file $file: $!");

    $self->{mtime} = (stat($file))[9];

    my %remain = %{$self->{_cache} || {}};
    while ($key = <$GROUP>) {
        $key = $1 if $key =~ m/(\w+)/;
	delete $remain{$key};
        next if exists $self->{_cache}{$key};

        if (-e "$self->{bbsroot}/group/$key") {
            $self->{_cache}{$key} = $self->module('Group')->new(
                $self->{bbsroot}, $key
            );
        }
        elsif (substr($key, 0, 1) eq '+' and
               -e "$self->{bbsroot}/group/".($key = substr($key, 1))) {
            %{$self->{_cache}} = (
                %{$self->{_cache}},
                %{OurNet::BBS::CVIC::Group->new($self->{bbsroot}, $key)},
            );
        }
        elsif (-e "$self->{bbsroot}/boards/$key/.DIR") {
            $self->{_cache}{$key} = $self->module('Board')->new(
                $self->{bbsroot}, $key
            );
        }
    }

    foreach my $del (keys(%remain)) {
	delete $self->{_cache}{$del};
    }
    close $GROUP;
}

sub DELETE {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";

    $self->refresh($key);
    return unless delete($self->{_cache}{$key});

    open(my $GROUP, $file) or die "Cannot read group file $file: $!";
    my $content = join ('', grep { not m/\b$key\b/ } <$GROUP>);
    close $GROUP;

    open($GROUP, '>', $file) or die "Cannot write group file $file: $!";
    print $GROUP $content;
    close $GROUP;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";

    return if exists $self->{_cache}{$key}; # doesn't make sense yet

    die "doesn't exists such group or board $key: panic!"
        unless (-e "$self->{bbsroot}/group/$key" or
                -e "$self->{bbsroot}/boards/$key/.DIR");

    open(my $GROUP, '>>', $file) or die "Cannot append group file $file: $!";
    print $GROUP $key, "\n";
    close $GROUP;
}

sub remove {
    my $self = shift;
    return unlink(join('/', $self->{bbsroot}, 'group', $self->{group}));
}

1;
