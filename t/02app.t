use strict;
use warnings;
use lib 't/lib';
use Test::More qw(no_plan);

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestApp;

my $test = Plack::Test->create(TestApp->to_app);

my $res = $test->request(GET '/');

is_deeply(decode_json($res->content), [ qw(id name) ]);
