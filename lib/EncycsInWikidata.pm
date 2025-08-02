package EncycsInWikidata;
use WikidataQuerier;
use CSVInput;
use strict;

my @Encycs = (
  {"label" => "BlackPast article", "property" => "P6723",
   "prefix" => "https://www.blackpast.org/",
   "filename" => "ref-blackpast.csv", "min" => 400000, "max" => 1000000},
  {"label" => "Encyclopedia of Science Fiction", "property" => "P5357",
   "prefix" => "https://sf-encyclopedia.com/entry/",
   "filename" => "ref-escifi.csv", "min" => 1000000, "max" => 2000000},
  {"label" => "Internet Encyclopedia of Philosophy", "property" => "P5088",
   "prefix" => "https://iep.utm.edu/",
   "filename" => "ref-iep.csv", "min" => 30000, "max" => 300000},
  {"label" => "Handbook of Texas article", "property" => "P6015",
   "prefix" => "https://tshaonline.org/handbook/online/articles/",
   "filename" => "ref-texas.csv", "min" => 300000, "max" => 1000000}
);

my $querytemplate = qq!
SELECT ?id ?idLabel ?value WHERE {?id wdt:<PROPERTY> ?value
  SERVICE wikibase:label
     { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" }
}
!;

sub refresh_csvs {
  my ($self, %params) = @_;
  my $querier = new WikidataQuerier;
  foreach my $encyc (@Encycs) {
    my $property = $encyc->{property};
    my $query = $querytemplate;
    $query =~ s/<PROPERTY>/$property/;
    my $path = $self->{dir} . $encyc->{filename};
    my $min = $encyc->{min};
    my $max = $encyc->{max};
    print "Attempting to query $query and write result to $path\n";
    $querier->write_managed_query(query=>$query, format=>"csv", path=>$path,
                                  min=>$min, max=>$max);
  }
}

# These files don't define relationships

sub relationships {
  return ();
}

sub _read_resourcelinks {
  my ($self, %params) = @_;
  $self->{resourcesbyqid} = {};
  foreach my $encyc (@Encycs) {
    my $path = $self->{dir} . $encyc->{filename};
    my $csv = new CSVInput(filename=>$path);
    my @csvlines = @{$csv->get_rows()};
    foreach my $line (@csvlines) {
      my $qid     = $line->{id};
      my $encycid = $line->{value};
      $qid =~ s/.*Q/Q/;                   # strip down to just the QID
      if ($qid && $encycid) {
        my $ref = {};
        $ref->{url} = $encyc->{prefix} . $encycid;
        $ref->{note} = $encyc->{label};
        push @{$self->{resourcesbyqid}->{$qid}}, $ref;
      }
    }
  }
}

sub resourcelinks {
  my ($self, %params) = @_;
  my $qid = $params{qid};
  if (!$self->{resourcesbyqid}) {
    $self->_read_resourcelinks();
  }
  if ($self->{resourcesbyqid}) {
    my $ref = $self->{resourcesbyqid}->{$qid};
    return () if (!$ref);
    return @{$ref};
  }
  return ();
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

