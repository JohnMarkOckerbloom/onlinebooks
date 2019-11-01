package OLBP::WikidataSource;
use strict;

my $wikidatauristem = "https://www.wikidata.org/wiki/";

my $wikidatahashfile = "wikidata.hsh";

sub get_wikidata_id {
  my ($self, %params) = @_;
  my $val = $self->{hash}->get_value(key=>$params{id});
  $val =~ s/\s.*//;
  return $val;
}

sub get_wikidata_uri {
  my ($self, %params) = @_;
  my $id = $self->get_wikidata_id(%params);
  return $id if (!$id);
  return $wikidatauristem . $id;
}

sub get_wikipedia_uri {
  my ($self, %params) = @_;
  my $val = $self->{hash}->get_value(key=>$params{id});
  if ($val =~ / (.*)/) {
    return $1;
  }
  return undef;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  my $fname = $self->{dir} . $wikidatahashfile;
  $self->{hash} = new OLBP::Hash(name=>"wikidata", filename=>$fname);
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

