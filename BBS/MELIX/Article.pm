package OurNet::BBS::MELIX::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE3::Article/;
use fields qw/_cache/;
use subs qw/STORE/;

BEGIN {__PACKAGE__->initvars()};

sub STORE {
    my ($self, $key, $value) = @_;
    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, substr($self->{name}, -1), $self->{name});
        unless (-s $file or substr($value, 0, 6) eq '§@ªÌ: ') {
            my $hdr = $self->{_cache}{header};
            my $temp;

            foreach my $head (qw/From Board Subject Date/) {
                $temp .= "$head: $hdr->{$head}\n" if exists $hdr->{$head};
            }

            foreach my $head (keys(%{$hdr})) {
                next if $head eq 'From' or $head eq 'Board' or
                        $head eq 'Subject' or $head eq 'Date';
                $temp .= "$head: $hdr->{$head}\n" if exists $hdr->{$head};
            }

            $value = "$temp\n$value" if $temp;
        }
        open _, ">$file" or die "cannot open $file";
        print _ $value;
        close _;
        $self->{btime} = (stat($file))[9];
        $self->{_cache}{$key} = $value;
    }
    else {
        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir, $self->{hdrfile});

        open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = time();
    }
}

1;
