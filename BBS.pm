# $File: //depot/OurNet-BBS/BBS.pm $ $Author: autrijus $
# $Revision: #33 $ $Change: 1685 $ $DateTime: 2001/09/03 23:10:33 $
# Documentation at the __END__

package OurNet::BBS;
use 5.006;

$OurNet::BBS::VERSION  = '1.6';

use strict;
use warnings;
use OurNet::BBS::Utils;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot brdshmkey maxboard/],
    '@FILES'    => [qw/bbsroot/],
    '@GROUPS'   => [qw/bbsroot/],
    '@SESSIONS' => [qw/bbsroot sessionshmkey maxsession chatport passwd/],
    '@USERS'    => [qw/bbsroot usershmkey maxuser/],
);

no strict 'refs';
my $sub_new = *{'new'}{CODE};

{
    no warnings qw/redefine/;

    sub new { 
	goto &{$sub_new} unless $_[0] eq __PACKAGE__;

	return $_[0]->fillmod(
	    (ref($_[1]) ? $_[1]->{backend} : $_[1]),  'BBS'
	)->new(@_[1 .. $#_])
    }           
}

# default permission settings
use constant readok  => 1;
use constant writeok => 0;

sub refresh_meta {
    my ($self, $key) = @_;

    return $self->fillin(
	$key, substr(ucfirst($key), 0, -1).'Group', 
	map { $self->{$_} } @{uc($key)}
    );
}

1;

__END__

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

        foreach my $article (@{$brd->{articles}}) {
            print "Found article: $article->{title}\n" 
		if $article->btime > $mtime;
        }

        $mtime = $brd->{articles}->mtime;
    }

=head1 DESCRIPTION

OurNet-BBS is a cross-protocol distributed network, built as an
abstraction layer over telnet BBS-based systems used in Hong Kong,
China and Taiwan. It implements a flexible object model for
different BBS backends, along with an asymmetric authentication
and remote procedure call protocol.

This project aims to become a I<protocol agnostic> middle ware
solution for identity-based information storage & retrieval,
much like the Project Jabber's goal toward instant messaging,
or Project JXTA's aim toward distributed services.

For some of its practical uses, search for C<OurNet::BBSApp>
on CPAN.

=head1 DESIGN GOALS

There are several design goals for the OurNet-BBS:

=head2 Secure Communication & Storage

The most fundamental weakness of thin-client architectures
is the vulnerability of tampering, either by intercepting
transmissions or preying on unencrypted data stored on
the centralized server. Therefore, OurNet-BBS I<MUST> provide
means to retrieve, forward and store data securely.

=head2 Multiple Representation Paradigms

In order to translate between heterogenous services within
a common network, OurNet-BBS I<MUST> accept both storage-based
(eg. HTTP/FreeNet/LDAP) and message-based (eg. Jabber/XML-RPC)
renderings, and be able to render into corresponding formats
(eg. HTML/XML/MIME).

=head2 Decentralized Syndication Support

Monolithic, single point-of-failure servers has remained 
as the state of art in telnet-based BBS networks since the
very beginning, which leads to its incapability to leverage
viewers, services and computing resources on client machines
as well as the high failure rate in online services.

While not an end in itself, OurNet-BBS I<MUST> provide a
clearly defined layer for writing interoperable agent and
services in a serverless environment, either by utilizing
existing networks (eg. Gnutella, JXTA, FreeNet) or by
creating its own network. 

=head1 COMPONENTS

Since OurNet-BBS is a large undertaking, its various components
are relatively independent with each other, and are better viewed
as sub-projects working collaboratively.

=head2 BBS Backends

OurNet-BBS I<MUST> provide backends for all major
telnet-based BBS systems, akin to C<DBD::*> database
access drivers.

These backends I<SHOULD> support all existing services
available through telnet-based interfaces, including
boards, articles, nested archives, board classes, user
info, mailbox, sessions, instant message, and chat rooms.

Backend developers are strongly encouraged to actively
abstract similiar file-based operations among components,
via the C<OurNet::BBS::Base> object framework.

All backends I<MUST> provide the same interface for Board,
Article and User components, and I<SHOULD> support Group
and Session wherever applicable.

=over 4

=item MAPLE2 / SOB / PTT / ProBBS (a.k.a. CVIC)

Instead of supporting the common subset of all M2 variants,
OurNet-BBS I<SHOULD> provide a complete coverage to their
unique feature and formats, and inherit as many common
components from MAPLE2 as possible.

=item MAPLE3 / MELIX

Because of the uncoordinated and heavily forked status of GPL'ed
MAPLE3 code, OurNet-BBS I<MAY> choose to ignore unpolished
features (eg. Board Class), and to target MELIX's implementation
instead.

MELIX's handling of MIME header and scripting language support
I<SHOULD> be utilized as the reference implementation, until
another system appears with superior capabilities.

=item FireBird2 / FireBird3

In addition to offering transparent access between Maple and
FireBird series, OurNet-BBS I<MAY> implement FireBird-specific
features available through its telnet interface, if possible.

=item ColaBBS / RexchenBBS / TwolightBBS / ...

Newer BBS systems unrelated to the Eagles-Phoenix ancestry
also I<MAY> be supported, if under substantial usage and/or
offers advanced features as OurNet-BBS' representation layer.

=back

=head2 Wrapper Backends

These backends I<SHOULD> map their native data representation
into traditional ones, and I<MAY> offer additional options
to control their behaviour. They I<SHOULD NOT> break any
semantics common to all traditional backends.

=over 4

=item RAM

This is the skeleton implementation which I<MUST> support
common subsets of all possible components, and serves as a
reference for resolving conflicts between backends. It also
I<MUST NOT> rely on any on-disk storage or operating system
dependent features.

=item BBSAgent

Because most existing BBS sites will not offer OurNet-BBS
service overnight, a translation layer over their telnet
interfaces I<MUST> be supported.

This backend I<SHOULD> implement FETCH interfaces of
Article, Board, User and Session components, and I<MAY>
provide STORE interfaces to them.

See L</Agent Platform> for a discussion on telnet-based agent
scripting interfaces.

=item NNTP

For transparent synchronization with Usenet nodes, this
backend I<MUST> implement a RFC977-compliant client,
and I<SHOULD> transmit MIME data without loss.

This backend I<MUST> supported Article and Board components,
and I<MAY> provide a Group component.

=item POP3 / MailBox / IMAP / SMTP

These backends I<MUST> support read/write operations with
consistency, and I<SHOULD> transmit MIME data without loss.

Two or more protocols I<MAY> be combined to provide a
read/write interface.

=item DBI

This backend I<MUST> support MySQL, PosgreSQL, MS SQL and
Oracle DBDs. It I<MUST> provide a reference schema of
neccessary fields for each components, and I<SHOULD> accept
other schemas using clear-defined configuration methods.

=back

=head2 Content Rendering

Some representation layers, such as stateless HTTP, does not allow
a transparent integration. Nevertheless, OurNet-BBS I<SHOULD> provide
rendering tools to perform batch import / export against different
targets.

=over 4

=item WebBBS Plug-in

This CGI-based interface I<MUST> be capable of handling user
sessions, authentication and have customizable templates.
It also I<SHOULD NOT> depend on any specific backend's 
behaviour.

=item Web Framework Integration

In addition to stand-alone dynamic rendering, OurNet-BBS also
I<MAY> offer integration support to major web frameworks
(eg. Slash, Zope, etc). Such integrations I<SHOULD> render
OurNet objects into HTML format without loss, and vice versa.

=item Cross-Backend Migration Kit

Since not every backends support all OurNet-BBS components,
it is sometimes neccessary for sites using existing systems
to convert to MELIX, in order to fully utilize the OurNet-BBS
platform.

Such migration kits I<MUST> perserve static data as much as
possible, and I<SHOULD> retain the same structure and content
in the OurNet perspective.

=back

=head2 Service Transports

XXX: To be determined

=over 4

=item OurNet-RPC / XML-RPC

=item Jabber

=item CORBA / SOAP / EJB / LDAP / etc

OurNet-BBS I<MAY> also offer additional bindings to these
protocols, provided that there are corresponding needs.

=back

=head2 Decentralized Networking

XXX: To be determined

=over 4

=item Discovery

=item Messaging

=item Authentication

=item Syndication

=back

=head2 Agent Platform

The medium-term goal for OurNet-BBS is to become a backend-independent
Agent platform, consisting of all interconnected OurNet nodes. It is
therefore neccessary to offer a common set of API and infrastructure
to encourage people writing OurNet Agents.

=over 4

=item Telnet Agents

Besides static storage handled by backends, many Internet services
needs to interact with OurNet (eg. BBS, IRC and Telnet) lacks a
cleanly-defined API layer. Thus, a generic wrapper module is needed.

This module I<MUST> provide an object-oriented interface to those
services, by simulating as a virtual user with action defined by
a script language. This language I<MUST> support both flow-control
and event-driven interfaces.

=item Access Control

This module I<MUST> support both traditional C<crypt()>-based
and asymmetric authentications. It also I<SHOULD> negotiate among
multiple available ciphers. The permission model I<MUST> allow
user-defined fine grained control, including ACL, OPCode locking,
and respects the default settings of each backends.

=item Transportable Objects

This module I<MUST> allow ircbot-like agents to deserialize 
and walk through nodes, to translating requests across heterogenous
services. It also I<MUST> allow each signed objects to be distributed
and discovered across OurNet, so each node could look at the source
code, run it in a Safe compartment, and if they like it, they could
sign it to vouch for its integrity. 

=back

=head2 Documentation

XXX: To be determined

=over 4

=item Architecture and Philosophy

=item Interface and Samples

=item Test Cases With Comments

=item Backend Developer's Guide

=item Agent Developer's Guide

=back

=head1 MILESTONES

=head2 Milestone 0 - v1.6 - 2001/09/01

This milestone gives the baseline of basic functionalities,
and a working prototype of RPC + Access Control network.
It also includes manpages and overviews.

    backend:	MAPLE2, PTT, MAPLE3, MELIX.
    wrapper:	RAM, BBSAgent, NNTP, MailBox.
    transport:	OurNet-RPC.
    agent:	Telnet Agents, Access Control (MELIX).

=head2 Milestone 1 - v1.7 - 2001/10/10

This milestone aims to provide a working public beta based on
old client/server model. It will focus on core stability, a
complete test case, and introductory materials.

    agent:	Access Control (MAPLE2).
    rendering:	Migration Toolkit.
    document:	Architecture & Philosophy,
		Interfaces & Samples,
		Test Cases With Comments.

=head2 Milestone 2 - v1.8 - 2001/11/20

This milestone is for co-operability toward developers. It
will have a fully-functional reference implementation of
Web rendering, as well as a procedural interface suitable
to bindings with other languages. An experimental discovery
network should be formed by this milestone.

    wrapper:	POP3/SMTP.
    transport:	XML-RPC.
    rendering:	WebBBS Plug-in.
    network:	Discovery.
    document:	Backend Developer's Guide.

=head2 Milestone 3 - v1.9 - 2001/01/01

Cross-node messaging, presence and session management are the
main purpose fors this milestone. By this release, we should
also gradually move away from depending on text-file based
storage.

    transport:	Jabber.
    wrapper:	DBI.
    network:	Messaging, Authentication.

=head2 Milestone 4 - v2.0 - 2002/02/10

This milestone turns existing OurNet network into a true Agent
Platform, by offering intention- and subscription- based
sydication between nodes.

    rendering:	Web Framework Integration.
    network:	Syndication.
    agent:	Transportable Objects.
    document:	Agent Developer's Guide.

=head1 HISTORY

=over 4

=item v1.6, Mon Sep  3 Mon Sep  3 23:07:36 CST 2001

Changed C<Server> and C<Client>'s default port from 7978 to 7979.

Complete ArticleGroup permission model for C<MELIX>.

A <-g> options now enables C<bbscomd> to accept guest-privileged connections.

Delete board / articles now works in file-based backends.

Changed C<DBI> to C<RAM>; it has nothing to do with DBI anyway.

Integrated the new set of design documents into manpage.

=item v1.6-delta, Mon Aug 28 01:47:18 CST 2001

Session support for C<MELIX> backend.

Purged C<LWP> support from tree; nobody's using it anyway.

Fixed context problems of C<NNTP> and C<OurNet> backends.

The C<OurNet> protocol could now pass back arguments by reference.

Passes tests on Win32 now.

Post-back of C<BBSAgent> and C<SessionGroup> fixed.

=item v1.6-gamma, Thu Aug 16 17:37:12 CST 2001

The test cases in C<t/> are now numbered, and OurNet-based tests
added. For the first time, all tests pass.

Implemented C<{'owner'}> fetch for C<CVIC> groups.

The chrono-ahead algorithm now works correctly for all backends,
so there will no longer be duplicate C<Message-ID>s.

Fixed the C<MAPLE3> backend's incestous relationship with C<MELIX>.

Upgraded the C<Authen> protocol to v0.3. Setting the flag
C<$OurNet::BBS::BYPASS_NEGOTIATION> now bypasses handshaking
altogether.

=item v1.6-beta, Tue Aug 14 03:31:10 CST 2001

A streamlined C<t/stdtest> base now applies to all three 
file-based backends.

The C<{''} = ...> STORE-as-PUSH semantics is fully supported.

Group metadata unified into hash-based C<{owner|title|id}>.

Compatibility for perl 5.7.x, including line disciplines.

The long-timed 'extra test' heisenbug has been eliminated.

=item v1.6-alpha, Sun Aug 12 19:03:08 CST 2001

Added the HISTORY secion in manpage.

Rewritten C<Base> to be C<overload>-based.

Eliminated C<ArrayProxy> and pseudohashes.
  
Uses C<Test::More> instead of C<Test>.

Improved MIME and mail address parsing regexes.

A much faster and robust C<NNTP> backend.

The C<DBI> backend rewritten to indicate style change.

=item v1.56, Mon Jul 23 02:12:06 2001

File access via C<FileGroup> components.

Group support for C<MAPLE3> with a twisted API.

Proper permission control for nearly all componetts.

Unix-style mailbox support via the C<Mailbox> backend.

CR/LF bug on Win32 eliminated.

=item v1.55, Wed Jun 20 06:17:16 2001

The full C<OurNet> authentication model.

Fixed C<UserGroup> for C<MAPLE*> backends.

A new Message-ID formula.

Fixed core dump in various, but not all, places.

Massive speed increase.

=item v1.54, Wed Jun 13 11:43:12 2001

This version implements the new C<OurNet> (formerly known as C<PlClient>)
asymmetric-key based authentication model, article/board permission model
for M3 backends, numerous bugfixes, win32 support, and much, much more.

=item v1.53, Sat Jun  9 11:09:26 2001

Full C<bbscomd> support; C<PlClient> is now a valid backend. (autrijus)

Finally fixed the internal object model; using multiple backends was
broken due to back-propagation of initvar() variables. (autrijus)

STORE into C<MAPLE*> backends should now update shm correctly. (autrijus)

Improved C<BBSAgent> error handling for fail-safe operations. (clkao)

Fixed hazard caused by remote empty (or deleted) articles. (clkao)

Nickname support for C<MAPLE2>/C<CVIC> is reimplemented. (clkao)

BBSAgent now matches nickname even in pathetic cases. (smartboy)

=item v1.52, Wed Jun  6 05:53:54 2001

Clean-up release to fix many 1.51 glitches, with added documentation
and test cases added.

=item v1.51, Sat Jun  2 07:05:18 2001

Forked out from C<libOurNet> distribution.

Vastly improved support for C<BBSAgent> backend to support C<ebx>,
with many parsing enhancement and templates from C<smartboy>.

=item v1.4-alpha4, Fri Mar 23 03:21:14 2001

Integrated the C<MAPLE3> backend.

=item v1.4-alpha3, Fri Jan 12 04:57:17 2001

First Win32 (ppm) release.

=item v1.4-alpha2, Mon Jan 15 07:39:00 2001

Adds C<LWP::Protocol> support and C<Session> components.

=item v1.4-alpha, Fri Jan 12 04:54:29 2001

First CPAN release, featuring the C<BBSAgent> backend.

=item v1.3, Fri Dec 29 05:40:11 2000

Provides simple remote access via C<OurNet::BBS::PlClient>.

=item v1.2, Thu Dec  7 05:02:39 2000

Backend abstraction revised; added C<PTT> backend by gugod.

=item v1.1, Tue Nov 21 19:00:33 2000

Initial commit, with C<CVIC> as the only backend.

=back

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
