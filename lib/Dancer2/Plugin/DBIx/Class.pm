package Dancer2::Plugin::DBIx::Class;

use Dancer2::Plugin;
use Carp;
use Class::C3::Componentised;

has schema_class => (
  is => 'ro',
  from_config => 1,
);

has connect_info => (
  is => 'rw',
  trigger => 'clear_schema',
  builder => sub {
    my ($self) = @_;
    my $config = $self->config;
    return [
      $config->{connect_info}
        ? @{$config->{connect_info}}
        : @{$config}{qw(dsn user password options)}
    ];
  }
);

has schema => (
  is => 'lazy',
  clearer => 1,
  builder => sub {
    my ($self) = @_;
    $self->_ensure_schema_class_loaded->connect(@{$self->connect_info});
  },
);

has export_prefix => (
	is => 'ro',
	predicate => 1,
   builder => sub {
    my ($self) = @_;
    my $config = $self->config;
    return $config->{export_prefix};
  }

);

sub _maybe_prefix_method {
  my ($self, $method) = @_;
  return $method unless $self->export_prefix;
  return join('_', $self->export_prefix, $method);
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
  croak 'No schema class defined' if !$_[0]->schema_class;
  eval { Class::C3::Componentised->ensure_class_loaded($_[0]->schema_class) };
  croak 'Schema class '.$_[0]->schema_class.' unable to load' if $@;
  return $_[0]->schema_class;
}

sub rs {
  my ($self, $rs) = @_;
  my $schema = $self->schema;
  return $schema->resultset($rs);
}

sub BUILD {
  my ($self) = @_;
  my $class = $self->_ensure_schema_class_loaded;
  my $call_rs = sub { shift->schema->resultset(@_) };
  my %kw;
  $kw{'rs'} = $call_rs;
  $kw{'rset'} = $call_rs;
  $kw{'resultset'} = $call_rs;
  $kw{'schema'} = sub { shift->schema(@_) };
  my @export_methods = (
    $self->_rs_name_methods, @{$self->export_schema_methods}
  );
  foreach my $exported_method (@export_methods) {
    $kw{$self->_maybe_prefix_method($exported_method)} = sub {
      shift->schema->$exported_method(@_);
    };
  }
  @{$self->keywords}{keys %kw} = values %kw;
}

1;
