#!/usr/bin/perl -w
use lib '../lib';

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 23 }

use OurNet::BBS;
use OurNet::BBS::DBI::Board;
use OurNet::BBS::DBI::Session;
use OurNet::BBS::DBI::User;

my $BBS;

ok($BBS = OurNet::BBS->new('DBI'));

# make a board...
$BBS->{boards}{test} = {
    title => 'test board',
    bm    => 'sysop',
};

my $brd = $BBS->{boards}{test};

# BOARDS test

ok(join(',', keys(%{$BBS->{boards}})), 'test');
ok($brd->{bm}, 'sysop');
ok($brd, $BBS->{boards}{test});

# push #1
push @{$brd->{articles}}, {
    title  => 'test title',
    author => 'user',
    body   => 'bodie',
};

ok($brd->{articles}[1]{author}, 'user');

# append #2
$brd->{articles}[2] = {
    title  => 'random title',
    author => 'smart',
    body   => 'bodie',
};

ok($brd->{articles}[2]{body}, qr/bodie/);
ok($brd->{articles}[2]{header}{From}, 'smart');
ok(index($brd->{articles}[2]{header}{'Message-ID'}, '@'), 37);

# alternative access

ok($brd->{articles}{$brd->{articles}[2]{id}}{body}, qr/bodie/);

# set #1
$brd->{articles}[1] = {title => 'changed title'};
ok($brd->{articles}[1]{title}, 'changed title');

# foreach iteration
my $flag;
foreach (@{$brd->{articles}}[1..$#{$brd->{articles}}]) {
    ok($_->{body}, qr/bodie/);
    ok($_->mtime);

    unless ($flag++) {
        # iterator kludge
        $BBS->{boards}{kitty} = {
            title => 'test board',
            bm    => 'sysop',
        };
        ok($BBS->{boards}{kitty}{bm}, 'sysop');
    }
}


# each interation
while (my ($k, $v) = each (%{$brd->{articles}})) {
    ok($v->{title}, $brd->{articles}{$k}{title});
}

# archiving
push @{$brd->{archives}}, @{$brd->{articles}}[1,2];
ok($brd->{archives}[2]{title}, qr/random title/);

# archive directory
push @{$brd->{archives}}, bless ({
    title  => 'Random Directory',
    author => 'random',
}, 'OurNet::BBS::DBI::ArticleGroup');

# is store successful?
ok($brd->{archives}[3]{author}, 'random');

# by-name fetch
my $name = $brd->{archives}[3]{id};
ok($name, $brd->{archives}[3]->name);

# push into new dir
push @{$brd->{archives}[3]}, {
    title  => 'turandot',
    author => 'aida',
    body   => 'satva',
};

ok($brd->{archives}[3][1]{title}, qr/turandot/);
ok($brd->{archives}[-1][1]{title}, qr/turandot/);

# new group
my $grp = $BBS->{groups}{home};

++$grp->{test};
ok(join('', keys(%{$BBS->{groups}})), 'home');

# group inside group
++$BBS->{groups}{rainbow}{home};
ok(join('', sort {$a cmp $b} keys(%{$BBS->{groups}})), 'homerainbow');

