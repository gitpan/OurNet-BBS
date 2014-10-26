# $File: //depot/OurNet-BBS/BBS/MAPLE2/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 1317 $ $DateTime: 2001/06/27 04:50:59 $

package OurNet::BBS::MAPLE2::ArticleGroup;

use strict;
use warnings;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board basepath name dir recno mtime btime _cache _phash/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring'    => 'Z33Z1Z14Z6Z73C',
        '$packsize'      => 128,
        '@packlist'      => [qw/id savemode author date title filemode/],
    );
}

my %chronos;

sub basedir {
    my $self = shift;

    no warnings 'uninitialized';

    return join('/', $self->{bbsroot}, $self->{basepath},
                     $self->{board}, $self->{dir});
}

sub new_id {
    my $self = shift;
    my ($id, $file);

    my $chrono = time();

    no warnings 'uninitialized';
    
    $chronos{$self->{board}} = $chrono 
        if $chrono > $chronos{$self->{board}};

    while ($id = "D.$chrono.A") {
        $file = join('/', $self->basedir(), $id);
        last unless -e $file;
        $chrono = ++$chronos{$self->{board}};
    }

    mkdir join('/', $self->basedir(), $self->{name});
    return $id;
}

sub refresh_id {
    my ($self, $key) = @_;

    $self->{name} ||= $self->new_id();

    my $file = join('/', $self->basedir(), '.DIR');

    return if $self->{btime} and (stat($file))[9] == $self->{btime}
              and defined $self->{recno};

    $self->{btime} = (stat($file))[9];

    local $/ = \$packsize;
    open(my $DIR, $file) or die "can't read DIR file for $self->{board}: $!";

    if (defined $self->{recno}) {
        seek $DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <$DIR>);
        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek $DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;
        while (my $data = <$DIR>) {
            @{$self->{_cache}}{@packlist} = unpack($packstring, $data);
            # print "$self->{_cache}{id} versus $self->{name}\n";
            last if ($self->{_cache}{id} eq $self->{name});
            $self->{recno}++;
        }
        if ($self->{_cache}{id} ne $self->{name}) {
            # die "not supposed to be here: $self->{_cache}{id}, $self->{name}";
            $self->{_cache}{id} = $self->{name};
            $self->{_cache}{author}   ||= 'guest.';
            $self->{_cache}{date}     = sprintf(
		"%2d/%02d", (localtime)[4] + 1, (localtime)[3]
	    );
            $self->{_cache}{title}    = '�� (untitled)';
            $self->{_cache}{filemode} = 0;

            open($DIR, '+>>', $file) 
		or die "can't write DIR file for $self->{board}: $!";
            print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close $DIR;

            mkdir join('/', $self->basedir(), $self->{name});
            open($DIR, '>', join('/', $self->basedir(), '.DIR'));
            close $DIR;

            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    no warnings qw/uninitialized numeric/;

    my $file = join('/', $self->basedir(), $self->{name}, '.DIR');
    my $name;

    if ($self->contains($key) or $key eq 'recno') {
        goto &refresh_id;
    }
    elsif (!defined($key) and $self->{dir}) {
        $self->refresh_id;
    }

    if ($key and $key ne int($key)) {
        # hash key -- no recaching needed
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module(substr($key, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $key,
                "$self->{dir}/$self->{name}",
            );

        $self->{_phash}[0][0]{$key} = $obj->recno+1;
        $self->{_phash}[0][$obj->recno+1] = $obj;

        return 1;
    }

    open(my $DIR, $file)
	or (warn "can't read DIR file for $file: $!", return);

    if ($key) {
        # out-of-bound check
        return if $key < 1 or $key > int((stat($file))[7] / $packsize);

        seek $DIR, $packsize * ($key-1), 0;
        read $DIR, $name, 33;
        $name = unpack('Z33', $name);
        # print "$name unpacked\n";

        return if $self->{_phash}[0][0]{$name} == $key;

        my $obj = $self->module(substr($name, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $name,
                "$self->{dir}/$self->{name}",
                $key-1,
            );

        $self->{_phash}[0][0]{$name} = $key;
        $self->{_phash}[0][$key] = $obj;

        close $DIR;
        return 1;
    }

    return if $self->timestamp($file);

    $self->{_phash}[0] = fields::phash(map {
        seek $DIR, $packsize * $_, 0;
        read $DIR, $name, 33;
        $name = unpack('Z33', $name);

        # return the thing
        ($name, $self->module(substr($name, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $name,
                "$self->{dir}/$self->{name}",
                $_,
        ));
    } (0..int((stat($file))[7] / $packsize)-1));

    close $DIR;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';

    if ($self->contains($key) or $key eq 'recno') {
        $self->refresh($key);
        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir(), '.DIR');

        open(my $DIR, '+<', $file) or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek $DIR, $packsize * $self->{recno}, 0;
        print $DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close $DIR;

	$self->timestamp($file);
    }
    else {
	my $obj;

	no warnings 'numeric';
        if ($key > 0 and exists $self->{_phash}[0][$key]) {
            $obj = $self->{_phash}[0][$key];
        }
        else {
            my $class = (UNIVERSAL::isa($value, "UNIVERSAL"))
                ? ref($value) : $self->module('Article');

            my $module = "$class.pm";
            $module =~ s|::|/|g;
            require $module;

            $obj = $class->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                undef,
                "$self->{dir}/$self->{name}",
                int($key) ? $key - 1 : undef,
            );
        }

        use Mail::Address;
        use Date::Parse;
        use Date::Format;
        
        if (exists $value->{header}) {
            my $adr = (Mail::Address->parse($value->{header}{From}))[0];
            if (ref($adr)) {
                $value->{author} = $adr->address;
		$value->{author} =~ s|\@.+$|.|;
                $value->{nick}   = $adr->comment;
		$value->{nick}   =~ s,^\(|\)$,,g;
            }

            $value->{date}  = time2str(
		'%m/%d', str2time($value->{header}{Date})
	    );
            $value->{date} =~ s/^0/ /; # how crude!
            $value->{title} = $value->{header}{Subject};
        }

        while (my ($k, $v) = each %{$value}) {
            $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} if ($value->{body});
        $self->refresh($key);
    }
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});

    my $file = join('/', $self->basedir(), $self->{name}, '.DIR');
    return 0 if $self->timestamp($file, 0);

    open(my $DIR, $file) or die "can't read DIR file $file: $!";

    my $board;
    foreach (0..int((stat($file))[7] / $packsize)-1) {
        print '.';
        seek $DIR, $packsize * $_, 0;
        read $DIR, $board, 33;
        return 1 if unpack('Z33', $board) eq $key;
    }

    close $DIR;
    return 0;
}

1;
