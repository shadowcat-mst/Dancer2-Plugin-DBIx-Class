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

sub register_resultset_name_method {
  my ($class, $source_name) = @_;
  my $method_name = $class->_source_name_to_method_name($source_name);
  unless ($class->can($method_name)) {
    $class->resultset_name_methods(
      { %{$class->resultset_name_methods}, $method_name => 1 },
    );
    no strict 'refs';
    *{"${class}::${method_name}"} = sub { shift->resultset($source_name) };
  }
}

sub register_all_resultset_name_methods {
  my ($class) = @_;
  $class->register_resultset_name_method($_) for $class->sources;
}

sub _source_name_to_method_name {
  my ($class, $source_name) = @_;
  my $phrase = join ' ', map {
    join(' ', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/)
  } split '::', $source_name;
  my $pluralised = Lingua::EN::Inflect::Phrase::to_PL($phrase);
  return join '_', split ' ', $pluralised;
}

1;
