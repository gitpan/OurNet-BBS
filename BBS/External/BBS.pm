# $File: //depot/OurNet-BBS/BBS/External/BBS.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2020 $ $DateTime: 2001/10/12 05:27:38 $

package OurNet::BBS::External::BBS;

use strict;
use base qw/OurNet::BBS/;
use fields qw/backend article_store article_fetch _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/article_store article_fetch/],
);

1;
