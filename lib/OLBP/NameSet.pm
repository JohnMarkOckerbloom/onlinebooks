package OLBP::NameSet;
use strict;
use OLBP::Name;


sub headings {
  my ($self) = @_;
  return keys ($self->{namehash});
}

sub informalname {
  my ($self, $heading) = @_;
  if ($self->{informalname}->{$heading}) {
    return $self->{informalname}->{$heading};
  }
  return OLBP::Name::informal($heading);
}

sub id_for_heading {
  my ($self, $heading) = @_;
  return $self->{id}->{$heading};
}

# might eventually want to break these reads out into a specific subclasses

sub _read_from_bookfile {
  my ($self, $path) = @_;
  open my $fh, "< $path" or die "Can't open $path";
  while (<$fh>) {
    my $name = "";
    if (/^(AUTHOR|EDITOR|ILLUSTRATOR|TRANSLATOR|CONTRIBUTOR)\+?\s+(.*\S)/) {
      $name = $2;
      $name =~ s/^\[[a-z0-9]+\]\s*//;   # remove wdb identifiers
      if ($name =~ /(.*)\|\*\s*(.*)/) {
        $name = $1;
        $self->{informalname}->{$name} = ($2 || $name);
      }
    }
    if (/^LCNSUB\+?\s+(.*\S)/) {
      $name = $1;
      $name =~ s/\s*--.*//;  # remove subject subdivision
    }
    if ($name) {
      $self->{namehash}->{$name} = 1;
    }
  }
  close $fh;
}

# We're assuming SKOS NT file for now
# If this gets too big, we might need to filter against supplied name set

my $NAPREF    = "http://id.loc.gov/authorities/names";
my $SKOSPREFLABEL =  "<http://www.w3.org/2004/02/skos/core#prefLabel>";
my $MADSPREFLABEL =  "<http://www.loc.gov/mads/rdf/v1#authoritativeLabel>";

sub _nt_decode {
  my $str = shift;
  if ($str =~ /([^\\]*)\\(.*)/) {
    my ($first, $rest) = ($1, $2);
    if ($rest =~ /^([\\\"])(.*)/) {
      return $first . $1 . _nt_decode($2);
    }
    if ($rest =~ /^n(.*)/) {
      return $first . "\n". _nt_decode($1);
    }
    if ($rest =~ /^r(.*)/) {
      return $first . "\r". _nt_decode($1);
    }
    if ($rest =~ /^t(.*)/) {
      return $first . "\t". _nt_decode($1);
    }
    if ($rest =~ /^u([0-9a-fA-F]{4})(.*)/) {
      return $first . chr(hex($1)) . _nt_decode($2);
    }
  }
  return $str;
}

sub _read_from_lcfile {
  my ($self, $path, $format) = @_;
  my $fh;
  my $property = $SKOSPREFLABEL;
  if ($format eq "mads") {
    $property = $MADSPREFLABEL;
  }
  if ($path =~ /.(gz|zip)$/) {
    open ($fh, "-|", "zcat $path") or die "can't open $path";
  } else {
    open ($fh, "< $path") or die "can't open $path";
  }
  binmode $fh, ":utf8";
  while (my $line = <$fh>) {
    if ($line =~ m!<$NAPREF/(.*)>\s+$property\s+"(.*)"(\@(EN|en))?\s*\.!) {
      my ($lcid, $label) = ($1, $2);
      $label = _nt_decode($label);
      $label =~ s/\s+/ /g;
      next if ($label =~ /\|/);           # forget author-title labels
      $self->{namehash}->{$label} = 1;
      $self->{id}->{$label} = $lcid;
    }
    # we could also get alt names if we thought them useful.  Might need
    #  to save under ID until we have a preferred name, though.
  }
  close $fh;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{namehash} = {};
  $self->{id} = {};
  $self->{informalname} = {};
  if ($params{bookfile}) {
    $self->_read_from_bookfile($params{bookfile});
  } elsif ($params{lcfile}) {
    $self->_read_from_lcfile($params{lcfile});
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
