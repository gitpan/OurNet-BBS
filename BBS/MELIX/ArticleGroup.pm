package OurNet::BBS::MELIX::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE3::ArticleGroup/;
use fields qw/_cache _phash/;
use subs qw/STORE/;

BEGIN {__PACKAGE__->initvars()};

sub STORE {
    my ($self, $key, $value) = @_;
    local $^W = 0; # turn off warnings

    if ($self->contains($key)) {
        $self->refresh($key);
        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir(), $self->{hdrfile});

        open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = $self->{_cache}{$key}->mtime;
    }
    else {
        my $obj;

        if ($key > 0 and exists $self->{_phash}[0][$key]) {
            $obj = $self->{_phash}[0][$key];
        }
        else {
            $obj = $self->module('Article', $value)->new({
                basepath => $self->{basepath},
                board    => $self->{board},
                hdrfile  => $self->{idxfile},
                recno    => int($key) ? $key - 1 : undef,
            });
        }
	$key = $obj->recno;
        if (ref($obj) =~ m|ArticleGroup|) {
            # do something here
            $obj->refresh('id');
        }
        else {
            use Mail::Address;
            use Date::Parse;
            use Date::Format;

            if ($value->{header}) {
                if (my $adr = (Mail::Address->parse(
		    $value->{header}{From}))[0]
		) {
                    $value->{author} = $adr->address;
                    $value->{nick} = $adr->comment;
                }

                $value->{date} = time2str(
		    '%y/%m/%d', str2time($value->{header}{Date})
		);
                $value->{title} = $value->{header}{Subject};
            }
            else {
                # traditional style
                $value->{header} = {
                    From    => "$value->{author} ($value->{nick})",
                    Date    => scalar localtime,
                    Subject => $value->{title},
                    Board   => $self->board,
                }
            }
        }

        while (my ($k, $v) = each %{$value}) {
            $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} if ($value->{body});
        $self->refresh($key);
        $self->{mtime} = $obj->mtime;
    }
}

1;
