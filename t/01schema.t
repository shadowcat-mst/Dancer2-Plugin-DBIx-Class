use strict;
use warnings;
use lib 't/lib';
use Test::More qw(no_plan);

use TestSchema;

my $s = TestSchema->clone;

is_deeply([ $s->humans->result_source->columns ], [ qw(id name) ]);
