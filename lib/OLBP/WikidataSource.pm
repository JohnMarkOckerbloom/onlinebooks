package OLBP::WikidataSource;
use JSON;
use strict;

my $wikidatauristem = "https://www.wikidata.org/wiki/";

my $wikidatajsonfile = "wikidata.json";

sub get_wikidata_id {
  my ($self, %params) = @_;
  return $self->{idtowikidata}->{$params{id}};
}

sub get_wikidata_uri {
  my ($self, %params) = @_;
  my $id = $self->get_wikidata_id(%params);
  return $id if (!$id);
  return $wikidatauristem . $id;
}

sub get_wikipedia_uri {
  my ($self, %params) = @_;
  return $self->{idtowikipedia}->{$params{id}};
}

sub _readjsonfile {
  my ($self, $path) = @_;
  my $str;
  open my $fh, "< $path" or return undef;
  binmode $fh, ":utf8";
  while (<$fh>) {
    $str .= $_;
  }
  close $fh;
  return $self->{parser}->decode($str);
}

sub _slurp_the_json {
  my ($self, %params) = @_;
  $self->{idtowikidata} = {};
  $self->{idtowikipedia} = {};
  $self->{parser} = JSON->new->allow_nonref;
  my $path = $self->{dir} . $wikidatajsonfile;
  $self->{json} = $self->_readjsonfile($path);
  return undef if (!$self->{json});
  my @array = @{$self->{json}};
  foreach my $entry (@{$self->{json}}) {
    my $olbpid = $entry->{olbpid};
    my $article = $entry->{article};
    my $wikidata = $entry->{wikidataid};
    $wikidata =~ s/.*\///;
    $self->{idtowikipedia}->{$olbpid} = $article;
    $self->{idtowikidata}->{$olbpid} = $wikidata;
  }
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->_slurp_the_json();
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

