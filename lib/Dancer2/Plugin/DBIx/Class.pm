package Dancer2::Plugin::DBIx::Class;

use Dancer2::Plugin;
use Class::C3::Componentised;
use curry;

has schema_class => (
  is => 'ro',
  from_config => 1,
  plugin_keyword => 1,
);

has connect_info => (
  is => 'rw',
  from_config => 1,
  plugin_keyword => 1,
  trigger => 'clear_schema',
);

has schema => (
  is => 'lazy',
  plugin_keyword => 1,
  clearer => 1,
  builder => sub {
    my ($self) = @_;
    $self->_ensure_schema_class_loaded->connect(
      map { ref($_) eq 'ARRAY' ? @$_ : @{$_}{qw(dns user password options)} }
        $self->connect_info
    );
  },
);

sub _ensure_schema_class_loaded {
  Class::C3::Componentised->ensure_class_loaded($_[0]->schema_class);
  return $_[0]->schema_class;
}

sub rs :PluginKeyword {
  my ($self, $rs) = @_;
  my $schema = $self->schema;
  if ($schema->resultset_name_method->{$rs}) {
    return $schema->$rs;
  }
  return $schema->resultset($rs);
}

sub BUILD {
  my ($self) = @_;
  my $class = $self->_ensure_schema_class_loaded;
  foreach my $rs_method (@{$class->resultset_name_methods}) {
    register $rs_method => $self->curry::weak::rs($rs_method);
  }
}

1;
