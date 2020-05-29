package TestSchema::Result::Human;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('humans');
__PACKAGE__->add_columns(qw(id name));

1;
