# $File: //depot/OurNet-BBS/ExtUtils/AutoInstall.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 2063 $ $DateTime: 2001/10/15 06:58:18 $

package ExtUtils::AutoInstall;
use 5.006;

$ExtUtils::AutoInstall::VERSION = '0.1';

use strict;
use warnings;

use Cwd;
use ExtUtils::MakeMaker;

=head1 NAME

ExtUtils::AutoInstall - Automatic installation of CPAN dependencies

=head1 SYNOPSIS

in F<Makefile.PL>:

    use ExtUtils::MakeMaker;
    use ExtUtils::AutoInstall (
	'' => [
	    # core modules
	    Package1	=> '0.01',
	],
	'Feature1', [
	    # do we want to install this feature by default?
	    sub { system('feature1 --version') == 0 },
	    Package2	=> '0.02',
	],
	'Feature2', [
	    # skips checking -- defaults to install
	    Package3	=> '0.03',
	],
    );

    WriteMakefile(
	AUTHOR          => 'Joe Hacker (joe@hacker.org)',
	ABSTRACT        => 'Perl Interface to Joe Hacker',
	NAME            => 'Joe::Hacker',
	VERSION_FROM    => 'Hacker.pm',
	DISTNAME        => 'Joe-Hacker',

	PREREQ_PM       => PREREQ_PM, # <== ADD THIS
    );

=head1 DESCRIPTION

B<ExtUtils::AutoInstall> lets module writers specify a more
sophisticated form of dependency information than MakeMaker's
C<PREREQ_PM> option.

Existingrequisites are grouped into B<features>, and the user could
specify yes/no on each one. The module writer may also supply
a test subroutine reference to determine the default choice.

The B<Core Features> marked by an empty feature name is an
exeption: all missing packages that belongs to it will be
installed without prompting the user.

Once B<ExtUtils::AutoInstall> knows which modules are needed,
it checks whether it's running under the B<CPAN> shell and should
let CPAN handle the dependency. If not so, a separate B<CPAN>
instance is created to install the required modules.

=head1 CAVEATS

Since this module is needed before writing F<Makefile>, it makes
little use as a CPAN module; hence each distribution must include
it in full. The only alternative I'm aware of, namely prompting
in F<Makefile.PL> to force user install it (cf. the B<Template>
Toolkit's dependency on B<AppConfig>) is not very desirable either.

If you have any solutions, please let me know. Thanks.

=cut

our $CORE_FEATURE = 'Core Features';

sub import {
    my ($class, $pkg) = (shift, caller(0));
    return unless @_; # nothing to do

    print "*** $class version ".$class->VERSION."\n";
    print "*** Checking for dependencies...\n";

    my $cwd = Cwd::cwd();
    my (@Missing, @Existing); # missing modules, existing modules

    while (my ($feature, $modules) = splice(@_, 0, 2)) {
	$feature = $CORE_FEATURE if $feature eq '';
	print "[$feature]\n";

	my @required;
	my $yes = (ref($modules->[0]) ne 'CODE' or &{shift(@$modules)});

	while (my ($mod, $ver) = splice(@$modules, 0, 2)) {
	    printf("- %-16s ...", $mod);

	    if (my $cur = _version_check($mod, $ver)) {
		print "loaded. ($cur >= $ver)\n";
		push @Existing, $mod => $ver;
	    }
	    else {
		print "failed! (needs $ver)\n";
		push @required, $mod => $ver;
	    }
	}

	next unless @required;

	push (@Missing, @required) 
	    if ($feature eq $CORE_FEATURE) or ExtUtils::MakeMaker::prompt(
		qq{==> Do you wish to install the }. (@required / 2).
		qq{ optional module(s)?}, $yes ? 'y' : 'n',
	    ) =~ /^[Yy]/;
    }

    if (@Missing) {
	print "*** Installing dependencies...\n" if @Missing;

	require CPAN; CPAN::Config->load;

	no warnings 'once';
	my $lock = MM->catfile($CPAN::Config->{cpan_home}, ".lock");

	if (-f $lock and open(LOCK, $lock) and <LOCK> == getppid()) {
	    print "Since we're running under CPAN, ".
		  "I'll just let it take care of us later.\n";
	}
	else {
	    foreach my $package (@Missing) {
		my $obj = CPAN::Shell->expand(Module => $package);
		$obj->install if $obj;
	    }
	}

	close LOCK;
    }

    chdir $cwd;

    no strict 'refs';
    *{"$pkg\::PREREQ_PM"} = sub { return { @Existing, @Missing } };

    print "*** $class finished.\n";
}

sub _load {
    my $mod = pop; # class/instance doesn't matter
    return eval qq{ use $mod; $mod->VERSION } || 0;
}

sub _version_check {
    my ($mod, $min) = @_;
    my $cur = _load($mod);

    if ($Sort::Versions::VERSION || _load('Sort::Versions')) {
	# use Sort::Versions as the sorting algorithm 
	return ((Sort::Versions::versioncmp($cur, $min) != -1) ? $cur : 0);
    }
    else {
	# plain comparison
	no warnings 'numeric';
	return ($cur >= $min ? $cur : 0);
    }
}


1;

__END__

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
