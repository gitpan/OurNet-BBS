#!/usr/bin/perl

use strict;
use Test;
use File::Path;
use File::Temp;

BEGIN { 
    plan tests => 6;
}

use OurNet::BBS;

ok(1);

my $prefix = File::Temp::tempdir();
my $count = 0; # sleep count

mkpath(["$prefix/boards", "$prefix/group", "$prefix/man/boards"])
    or die "Cannot make $prefix";

open(BOARDS, ">$prefix/.BOARDS") or die "Cannot make $prefix/.BOARDS: $!";
close BOARDS;

my $port = 2000 + int(rand(100));

$OurNet::BBS::DEBUG = 1;

if (fork()) {
    ok(my $BBS = OurNet::BBS->new('MAPLE2', $prefix));

    # make a board...
    my $brd = $BBS->{boards}{test} = {
	title => 'test board',
	bm    => 'sysop',
    };

    # set an article...
    push @{$brd->{articles}}, {
        title  => 'title',
        author => 'author', 
        body   => 'body',
    };

    $brd->daemonize($port) 
	unless my $pid = fork();

    while ($count++ < 5 and $brd->{articles}[1]{title} eq 'title') {
	sleep 1;
    }

    ok(kill(1, $pid));
    ok($brd->{title}, 'new board');
    ok($brd->{bm}, $brd->{title});
    ok($brd->{articles}[1]{title}, 'new title');

    rmtree($prefix, 0, 1);
} 
else {
    while ($count++ < 5 and not -e "$prefix/boards/test/.DIR") {
        sleep 1;
    }


    my $brd;

    $count = 0;

    while ($count++ < 5 and !$brd) {
	$brd = eval { OurNet::BBS->new('OurNet', 'localhost', $port) };
        sleep 1;
    }

    $brd->{title} = 'new board';

    while (my ($k, $v) = each(%{$brd})) {
	if ($k eq 'bm') {
	    $brd->{$k} = $brd->{title};
	}
    }

    my $art = $brd->{articles};
    $art->[1]{title} = 'new title';
}

