package DBIx::Class::Schema::ResultSetNames;

use strict;
use warnings;
use Lingua::EN::Inflect::Phrase;
use base qw(DBIx::Class::Schema);

__PACKAGE__->mk_group_accessors(inherited => 'resultset_name_methods');

__PACKAGE__->resultset_name_methods({});

sub _register_source {
  my ($class, $source_name, @rest) = @_;
  my $source = $class->next::method($source_name, @rest);
  $class->register_resultset_name_method($source_name);
  return $source;
}

sub _ensure_resultset_name_method {
  my ($class, $name, $sub) = @_;
  return if $class->can($name);
  {
    no strict 'refs';
    *{"${class}::${name}"} = $sub;
  }
  $class->resultset_name_methods(
    { %{$class->resultset_name_methods}, $name => 1 },
  );
  return;
}

sub register_resultset_name_methods {
  my ($class, $source_name) = @_;
  my $method_name = $class->_source_name_to_method_name($source_name);
  my $plural_name = $class->_source_name_to_plural_name($source_name);
  $class->_ensure_resultset_name_method(
    $method_name => sub {
      my ($self, @args) = @_;
      die "Can't call ${method_name} without arguments" unless @args;
      $self->resultset($source_name)->find(@args);
    }
  );
  $class->_ensure_resultset_name_method(
    $plural_name => sub {
      my ($self, @args) = @_;
      my $rs = $self->resultset($source_name);
      return $rs unless @args;
      return $rs->search(@args);
    }
  );
  return;
}

sub register_all_resultset_name_methods {
  my ($class) = @_;
  $class->register_resultset_name_methods($_) for $class->sources;
  return;
}

sub _source_name_to_phrase {
  my ($class, $source_name) = @_;
  join ' ', map {
    join(' ', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/)
  } split '::', $source_name;
}

sub _source_name_to_method_name {
  my ($class, $source_name) = @_;
  my $phrase = $class->_source_name_to_phrase($source_name);
  return join '_', split ' ', $phrase;
}

sub _source_name_to_plural_name {
  my ($class, $source_name) = @_;
  my $phrase = $class->_source_name_to_phrase($source_name);
  my $pluralised = Lingua::EN::Inflect::Phrase::to_PL($phrase);
  return join '_', split ' ', $pluralised;
}

1;
