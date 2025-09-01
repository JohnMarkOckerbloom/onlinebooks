package LCIDRecord;
use strict;
use JSON;

my $IDPREFIX         = "http://id.loc.gov/";
my $AGENTPREFIX      = $IDPREFIX . "rwo/agents/";
my $AUTHORITYPREFIX  = $IDPREFIX . "authorities/";
my $LCNAMEPREFIX     = $AUTHORITYPREFIX . "names/";
my $LCSUBPREFIX      = $AUTHORITYPREFIX . "subjects/";

my $MADSPREFIX         = "http://www.loc.gov/mads/";
my $RWOPROPERTY        = $MADSPREFIX . "rdf/v1#identifiesRWO";
my $OCCUPATIONPROPERTY = $MADSPREFIX . "rdf/v1#occupation";
my $AUTHLABELPROPERTY  = $MADSPREFIX . "rdf/v1#authoritativeLabel";
my $SEEALSOPROPERTY    = "http://www.w3.org/2000/01/rdf-schema#seeAlso";

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

sub _get_element_with_id {
  my ($json, $id) = @_;
  return undef if (!$json);
  for (my $i = 0; $json->[$i]; $i++) {
    if ($json->[$i]->{'@id'} eq $id) {
      return $json->[$i];
    }
  }
  return undef;
}

# utility that flattens out array with references to ID

sub _ids_from_array {
  my ($idarrayref) = @_;
  my @list = ();
  return @list if (!$idarrayref);
  foreach my $ref (@{$idarrayref}) {
    push @list, $ref->{'@id'} if ($ref->{'@id'});
  }
  return @list;
}

# utility that gets (first) authoritative label value,
#  optionally filtering by ID prefix and language

sub _authoritative_label {
  my ($json, $prefix, $language) = @_;
  my $id = $json->{'@id'};
  return undef if ($prefix && index($id, $prefix));
  my $arrayref = $json->{$AUTHLABELPROPERTY};
  return undef if (!$arrayref);
  foreach my $member (@{$arrayref}) {
    if (!$language || ($language eq $member->{'@language'})) {
      return $member->{'@value'};
    }
  }
  return undef;
}

# This gets only the RWO ID that's in the LC namespace

sub get_rwo_id {
  my ($self, %params) = @_;
  my $lcid = $self->{lcid};
  my $fullid = $LCNAMEPREFIX . $lcid;
  my $json = $self->{json};
  my $element = _get_element_with_id($json, $fullid);
  return undef if (!$element);
  my $rwoidarray = $element->{$RWOPROPERTY};
  return undef if (!$rwoidarray);
  my @idlist = _ids_from_array($rwoidarray);
  foreach my $id (@idlist) {
    if (!index($id, $AGENTPREFIX)) {
      return $id;
    }
  }
  return undef;
}

# Returns a list of the occupations named in the file,
# or an empty list if none found
#
# The occupations are the string values of the IDs referred to
#  by the occupations property of the name's real world object

sub get_occupations {
  my ($self, %params) = @_;
  my $rwo = $self->get_rwo_id();
  return () if (!$rwo);
  my $json = $self->{json};
  my $element = _get_element_with_id($json, $rwo);
  return () if (!$rwo);
  my $occrefref = $element->{$OCCUPATIONPROPERTY};
  my @occrefs = _ids_from_array($occrefref);
  my @occupations = ();
  foreach my $ref (@occrefs) {
    my $refjson = _get_element_with_id($json, $ref);
    my $str = _authoritative_label($refjson, $LCSUBPREFIX, "en");
    if ($str) {
      push @occupations, $str;
    }
  }
  # print "I found these occupations: ".  join("; ", @occupations) . "\n";
  return @occupations;
}

# Returns a list of the "see also" headings named in the file,
# or an empty list if none found
#
# The occupations are the string values of the IDs referred to
#  by the see property of the name's object

sub get_seealsos {
  my ($self, %params) = @_;
  my $lcid = $self->{lcid};
  my $fullid = $LCNAMEPREFIX . $lcid;
  my $json = $self->{json};
  my $element = _get_element_with_id($json, $fullid);
  return () if (!$element);
  my $seealsoref = $element->{$SEEALSOPROPERTY};
  my @seealsorefs = _ids_from_array($seealsoref);
  my @seealsos = ();
  foreach my $ref (@seealsorefs) {
    my $refjson = _get_element_with_id($json, $ref);
    my $str = _authoritative_label($refjson, $LCNAMEPREFIX);
    if ($str) {
      push @seealsos, $str;
    }
  }
  if (scalar(@seealsos)) {
    print "I found these see alsos for $lcid ".  join("; ", @seealsos) . "\n";
  }
  return @seealsos;
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{parser} = $params{parser} || JSON->new->allow_nonref;
  $self->{lcid} = $params{lcid};
  $self->{path} = $params{path};
  if ($self->{path}) {
    $self->{json} = $self->_readjsonfile($self->{path});
  }
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

