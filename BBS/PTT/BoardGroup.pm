# $File: //depot/OurNet-BBS/BBS/PTT/BoardGroup.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1204 $ $DateTime: 2001/06/18 19:29:55 $

package OurNet::BBS::PTT::BoardGroup;

use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_cache _shm _shmid/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'Z13Z49Z39LZ3LZ3CLLLLZ120',
        '$packsize'   => 120,
        '@packlist'   => [
            qw/id title bm brdattr pad bupdate pad2 bvote vtime
               level uid gid pad3/
         ],

    )
};

1;
