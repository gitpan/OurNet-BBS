# $File: //depot/OurNet-BBS/BBS/Firebird3/Article.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2916 $ $DateTime: 2002/01/26 23:37:01 $

package OurNet::BBS::Firebird3::Article;

use strict;
use base qw/OurNet::BBS::MAPLE2::Article/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$HEAD_REGEX' => qr/發信人: ([^ \(]+)\s?(?:\((.+?)\) )?[^\015\012]*\015?\012標  題: (.*?)\015?\012發信站: [^(]+\((.+?)\)[^\015\012]*\015?\012.*\015?\012/,
);

sub writeok { 0 };
sub readok { 1 };

1;
