# $File: //depot/OurNet-BBS/BBS/Firebird3/Article.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::Article;

use strict;
use base qw/OurNet::BBS::MAPLE2::Article/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$HEAD_REGEX' => qr/�o�H�H: ([^ \(]+)\s?(?:\((.+?)\) )?[^\015\012]*\015?\012��  �D: (.*?)\015?\012�o�H��: [^(]+\((.+?)\)[^\015\012]*\015?\012.*\015?\012/,
);

sub writeok { 0 };
sub readok { 1 };

1;
