package Dancer2::Plugin::DBIx::Class;

use Dancer2::Plugin;
use Class::C3::Componentised;

has schema_class => (
  is => 'ro',
  from_config => 1,
);

has connect_info => (
  is => 'rw',
  from_config => 1,
  trigger => 'clear_schema',
);

has schema => (
  is => 'lazy',
  clearer => 1,
  builder => sub {
    my ($self) = @_;
    $self->_ensure_schema_class_loaded->connect(
      map { ref($_) eq 'ARRAY' ? @$_ : @{$_}{qw(dsn user password options)} }
        $self->connect_info
    );
  },
);

has method_prefix => (is => 'ro', predicate => 1);

sub _maybe_prefix_method {
  my ($self, $method) = @_;
  return $method unless $self->method_prefix;
  return join('_', $self->method_prefix, $method);
}

has export_schema_methods => (
  is => 'ro',
  default => sub { [] }
);

sub _rs_name_methods {
  my ($self) = @_;
  my $class = $self->_ensure_schema_class_loaded;
  return () unless $class->can('resultset_name_methods');
  sort keys %{$class->resultset_name_methods};
}

sub _has_rs_name_method {
  my ($self, $has) = @_;
  my $class = $self->_ensure_schema_class_loaded;
  return 0 unless $class->can('resultset_name_methods');
  0+!!$class->resultset_name_methods->{$has};
}

sub _ensure_schema_class_loaded {
  Class::C3::Componentised->ensure_class_loaded($_[0]->schema_class);
  return $_[0]->schema_class;
}

sub rs :PluginKeyword( rs rset resultset ) {
  my ($self, $rs) = @_;
  my $schema = $self->schema;
  return $schema->resultset($rs);
}

sub BUILD {
  my ($self) = @_;
  my $class = $self->_ensure_schema_class_loaded;
  my $call_rs = sub { shift->resultset(@_) };
  register $self->_maybe_prefix_method('rs') => $call_rs;
  register $self->_maybe_prefix_method('rset') => $call_rs;
  register $self->_maybe_prefix_method('resultset') => $call_rs;
  register $self->_maybe_prefix_method('schema') => sub { shift->schema(@_) };
  my @export_methods = (
    $self->_rs_name_methods, @{$self->export_schema_methods}, 'resultset'
  );
  foreach my $exported_method (@export_methods) {
    register $self->_maybe_prefix_method($exported_method) => sub {
      shift->schema->$exported_method(@_);
    };
  }
}

1;
