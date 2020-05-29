package TestApp;

use Dancer2;

BEGIN {
  set serializer => 'JSON';

  set plugins => { 'DBIx::Class' => {
    schema_class => 'TestSchema',
  } };
}

use Dancer2::Plugin::DBIx::Class;

get '/' => sub { [ humans()->result_source->columns ] };

1;
