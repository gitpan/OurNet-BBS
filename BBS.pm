# $File: //depot/OurNet-BBS/BBS.pm $ $Author: autrijus $
# $Revision: #25 $ $Change: 1482 $ $DateTime: 2001/07/23 01:18:05 $

package OurNet::BBS;
require 5.006;

$OurNet::BBS::VERSION  = '1.56';

use strict;
use base qw/OurNet::BBS::Base/;
use OurNet::BBS::Utils;

=head1 NAME

OurNet::BBS - Component Object Model for BBS systems

=head1 SYNOPSIS

    use strict;
    use OurNet::BBS;

    my $backend = 'MELIX'; # use the Melix BBS backend
    my $bbsroot = '/home/melix';
    my $board   = 'sysop';
    my $BBS     = OurNet::BBS->new($backend, $bbsroot);
    my $brd     = $BBS->{boards}{$board};
    my $mtime;

    printf (
        "This BBS has %d boards, %d groups.\n",
        scalar keys(%{$BBS->{boards}}),
        scalar keys(%{$BBS->{groups}}),
    );

    eval { $mtime = $brd->{articles}->mtime };
    die "Error: cannot read board $board -- $@\n" if $@;

    printf (
        "The $board board has %d articles, %d toplevel archive entries.\n",
        $#{$brd->{articles}}, $#{$brd->{archives}},
    );

    # A simple Sysop board article monitor
    print "Watching for new articles...\n";

    while (1) {
        print "=== wait here ($mtime) ===\n";
        sleep 5 until ($brd->{articles}->refresh);

        foreach my $article (@{$brd->{articles}}[1..$#{$brd->{articles}}]) {
            print "Found article: $article->{title}\n" 
		if $article->btime > $mtime;
        }

        $mtime = $brd->{articles}->mtime;
    }

=head1 DESCRIPTION

OurNet::BBS implements a flexible object model for different 
BBS backends, along with an asymmetric authentication and
remote procedure call protocol.

For some of its practical uses, search for 'OurNet::BBSApp' 
on CPAN.

More detailed document is expected to appear soon.

=cut

BEGIN { 
    __PACKAGE__->initvars(
	'@BOARDS'   => [qw/bbsroot brdshmkey maxboard/],
	'@FILES'    => [qw/bbsroot/],
	'@GROUPS'   => [qw/bbsroot/],
        '@SESSIONS' => [qw/bbsroot sessionshmkey maxsesions chatport passwd/],
	'@USERS'    => [qw/bbsroot usershmkey maxuser/],
    );
}

sub new { 
    return ($_[0] eq __PACKAGE__)
	? $_[0]->fillmod(
		(ref($_[1]) ? $_[1]->{backend} : $_[1]),  'BBS'
	    )->new(@_[1..$#_])
	: OurNet::BBS::Base::new(@_);
}           

# default permission settings
sub readok { 1 }
sub writeok { 0 }

sub refresh_meta {
    my ($self, $key) = @_;

    no strict 'refs';

    return $self->fillin(
	$key, substr(ucfirst($key), 0, -1).'Group', 
	map { $self->{$_} } @{uc($key)}
    );
}

1;

__END__

=head1 AUTHORS

Chia-Liang Kao E<lt>clkao@clkao.org>,
Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Chia-Liang Kao E<lt>clkao@clkao.org>,
		  Autrijus Tang E<lt>autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
