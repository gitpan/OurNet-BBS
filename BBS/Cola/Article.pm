# $File: //depot/OurNet-BBS/BBS/Cola/Article.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1865 $ $DateTime: 2001/09/19 06:24:11 $

package OurNet::BBS::Cola::Article;

use strict;
use base qw/OurNet::BBS::MAPLE2::Article/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$HEAD_REGEX' => qr/[^\s]+ 作者 [^\s]+ ([^ \(]+)\s?(?:\((.+?)\) )?[^\015\012]*\015\012[^\s]+ 標題 [^\s]+ (.*?)\s*\x1b\[m\015\012[^\s]+ 時間 [^\s]+ (.+?)\s+\x1b\[m\015\012.+\015\012/,
);

sub writeok { 0 };
sub readok { 1 };

1;
