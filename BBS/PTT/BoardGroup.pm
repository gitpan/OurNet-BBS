# $File: //depot/OurNet-BBS/BBS/PTT/BoardGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1525 $ $DateTime: 2001/08/17 22:49:33 $

package OurNet::BBS::PTT::BoardGroup;

use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_ego _hash _shm _shmid/;
use OurNet::BBS::Base (
    '$packstring' => 'Z13Z49Z39LZ3LZ3CLLLLZ120',
    '$packsize'   => 120,
    '@packlist'   => [
        qw/id title bm brdattr pad bupdate pad2 bvote vtime
           level uid gid pad3/
     ],
);

1;
