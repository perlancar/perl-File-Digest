#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::Digest qw(digest_files);
use File::Temp qw(tempdir);
use File::Slurper qw(write_text);

my $dir = tempdir(CLEANUP=>1);
write_text("$dir/1", "one");
write_text("$dir/2", "two");

subtest "algoritm md5" => sub {
    my $res = digest_files(
        algorithm=>"md5", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"f97c5d29941bfb1b2fdab0874906ab82"},
            {file=>"$dir/2", digest=>"b8a9f715dbb64fd5c56e7783c6820a61"},
        ],
    );
};

subtest "algoritm sha1" => sub {
    my $res = digest_files(
        algorithm=>"sha1", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"fe05bcdcdc4928012781a5f1a2a77cbb5398e106"},
            {file=>"$dir/2", digest=>"ad782ecdac770fc6eb9a62e44f90873fb97fb26b"},
        ],
    );
};

subtest "algoritm sha256" => sub {
    my $res = digest_files(
        algorithm=>"sha256", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed"},
            {file=>"$dir/2", digest=>"3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3"},
        ],
    );
};

subtest "algoritm crc32" => sub {
    my $res = digest_files(
        algorithm=>"crc32", files=>["$dir/1", "$dir/2", "$dir/3"],
    );
    is($res->[0], 207) or diag explain $res;
    is_deeply(
        $res->[2],
        [
            {file=>"$dir/1", digest=>"7a6c86f1"},
            {file=>"$dir/2", digest=>"11ca8a66"},
        ],
    );
};

done_testing;
