package Dancer2::Plugin::DBIx::Class;

use Dancer2::Plugin;
use Class::C3::Componentised;

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
      map { ref($_) eq 'ARRAY' ? @$_ : @{$_}{qw(dsn user password options)} }
        $self->connect_info
    );
  },
);

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
  my @export_methods = (
    $self->_rs_name_methods, @{$self->export_schema_methods}
  );
  foreach my $exported_method (@export_methods) {
    register $exported_method => sub {
      shift->schema->$exported_method(@_);
    };
  }
}

1;
