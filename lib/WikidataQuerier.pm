package WikidataQuerier;
use LWP::UserAgent;
use strict;

my $DEFAULT_AGENT = "OnlineBooks/0.1";
my $DEFAULT_ENDPOINT = "https://query.wikidata.org/sparql";

sub query_wikidata {
  my ($self, %params) = @_;
  my $query = $params{query};
  my $format = $params{format};
  my $agent = $self->{ua};
  my $endpointurl = $self->{endpoint};
  my $queryURL = "${endpointurl}?query=${query}";
  my $req;
  if ($format eq "csv") {
    # CSV requests have to be specified in the header
    my $header = ["Accept"=>"text/csv"];
    $req = new HTTP::Request("GET", $queryURL, $header);
  } else {
    $queryURL .= "&format=${format}";
    $req = new HTTP::Request(GET=>$queryURL);
  }
  # Seem to be having problems with cert verification, so turning off for now
  # $agent->ssl_opts( "verify_hostname" => 0 );
  my $res = $agent->request($req);
  if ($res->is_success) {
     my $content = $res->content;
     utf8::decode($content);
     return $content;
  }
  print STDERR $res->status_line, "\n";
  return undef;
}

sub _shift_file {
  my ($oldpath, $newpath, $minsize, $maxsize) = @_;
  my $size = -s $oldpath;
  if (!$size ||
     ($minsize && ($size < $minsize))  ||
     ($maxsize && ($size > $maxsize))) {
    return 0;
  }
  rename($oldpath, $newpath);
  return 1;
}

sub _writetofile {
  my ($name, $string) = @_;
  open my $fh, "> $name" or die "Can't open $name for writing";
  binmode $fh, ":utf8";
  print $fh $string;
  close $fh;
}

# write_managed query takes the result of the query and
# records the result (either outputting literally or calling an 
# output function) into a staging file, copying it to the production file
# if the result's size is acceptable (between min and max size)
# returns 1 on success, 0 on failure

sub write_managed_query {
  my ($self, %params) = @_;
  my $path = $params{path};
  return 0 if (!$path);
  my $staging = $params{staging};
  my $transformer = $params{transformer};
  if (!$staging) {
    $staging = $path;
    $staging =~ s/\.(\w+)$/-stage.$1/;
    return 0 if ($staging eq $path);
  }
  my $result = $self->query_wikidata(%params);
  return 0 if (!defined($result));
  if ($transformer) {
    # handle output through the provided transformation function
    $transformer->($staging, $result);
  } else {
    # otherwise, just write out the results
    _writetofile($staging, $result);
  }
  if (!_shift_file($staging, $path, $params{min}, $params{max})) {
    print STDERR "Didn't like the look of $staging\n";
    return 0;
  }
  return 1;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{agentstring} = $params{agentstring} || $DEFAULT_AGENT;
  $self->{endpoint} = $params{endpoint} || $DEFAULT_ENDPOINT;
  $self->{ua} = new LWP::UserAgent;
  $self->{ua}->agent($self->{agentstring});
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

