# $File: //depot/OurNet-BBS/lib/Bundle/OurNet.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1896 $ $DateTime: 2001/09/24 18:44:23 $

package Bundle::OurNet;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::OurNet - OurNet::BBS and prerequisites

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::OurNet'>

=head1 CONTENTS

# Below is a bunch of helpful dependency diagrams.

Net::Telnet        # -*

Test::Simple       # -*

OurNet::BBSAgent   #  -----*

Storable           # -*    |

Net::Daemon        # -*    |

RPC::PlServer      #  -----*

Digest::MD5        # ------*

File::Temp         # -*    |

Data::Dumper       # -*    |

Net::NNTP          #  -----*

Date::Parse        # -*    |

Mail::Address      # -*    |

MIME::Tools        #  --*  |

IO::Stringy        #  --*  |

Mail::Box          #    ---*

Term::ReadKey      # ------*

enum               # ------*

Class::MethodMaker # -*      |

GnuPG::Interface   #  -------*

Crypt::Rijndael    # --------*

MIME::Base64       # --------*

Compress::Zlib     # --------*

OurNet::BBS        #       --*

OurNet::BBSApp::Sync # XXX extra

=head1 DESCRIPTION

This bundle includes all that's needed to run the OurNet::BBS suite.

=head1 AUTHORS

Chia-Liang Kao <clkao@clkao.org>,
Autrijus Tang <autrijus@autrijus.org>.

=head1 COPYRIGHT

Copyright 2001 by Chia-Liang Kao <clkao@clkao.org>,
                  Autrijus Tang <autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
