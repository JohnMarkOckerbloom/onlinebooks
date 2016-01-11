package OLBP::SubjectGeo;
use strict;

sub _read_geofile {
  my ($self, %params) = @_;
  $self->{filecheck} = 1;
  my $file = $self->{file};
  return if (!$file);
  open GEO, "< $file" or return 0;
  while (my $line = <GEO>) {
    chop $line;
    my ($place, $abbrev, @regions) = split /\|/, $line;
    if (!$abbrev) {
      $abbrev = $place;
    }
    $self->{expand}->{$abbrev} = $place;
    $self->{abbrev}->{$place} = $abbrev;
    foreach my $region (@regions) {
      if ($region) {
        push @{$self->{region}->{$place}}, $region;
      }
    }
  }
  close GEO;
}

# get_geoparents:
# We look for unqualigied terms that are of a form that looks like it
# could be a geographic term, and return a likely parent candidate.
# (We leave it to the calling routine to determine whether the parent exists).
# For an Abbrev. and Statename existign in our database, we map:
#
# String (Abbrev.)                      -> statename of Abbrev.
# String1 (String2, Abbrev. [ : Type])  -> String2 (Abbrev.)
# Statename                             -> country of Statename

sub get_geoparents {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  return () if (!$heading || $heading =~ /--/);
  if (!$self->{filecheck}) {
    $self->_read_geofile();
  }
  if ($heading =~ /.*\s+\((.*)\)$/) {
    my $place = $1;
    if ($place =~ /(.*) : [A-Z]\w+$/) {
      # handles things like "Cornwall (England : County)"
      $place = $1;
    }
    my $state = $self->{expand}->{$place};
    return $state if ($state);
    if ($place =~ /^(.*) and (.*)$/ &&
        $self->{expand}->{$1} && $self->{expand}->{$2}) {
      return ($self->{expand}->{$1}, $self->{expand}->{$2});
    }
    if ($place =~ /^(.*), (.*)$/ && $self->{expand}->{$2}) {
      return "$1 ($2)";
    }
  }
  if ($self->{region}->{$heading}) {
    return @{$self->{region}->{$heading}};
  }
  return ();
}

# get_geoheading:
# We get the heading version of a compound term, if one exists.
# The mapping is as follows, if Statename is known
#
# Statename -- Location      -> Location (Abbrev.)

sub get_geoheading {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  if ($heading =~ /(.*)\s+--\s+(.*)/ && $self->{abbrev}->{$1}) {
    my ($state, $loc) = ($1, $2);
    if ($loc =~ /(.*)\s+\((\w*)\)$/) {
      # handle cases like "Spain -- Valencia (Province)"
      # -> "Valencia (Spain : Province)"
      return "$1 (" . $self->{abbrev}->{$state} . " : " . $2 . ")";
    }
    return "$loc (" . $self->{abbrev}->{$state} . ")";
  }
  return "";
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{file} = $params{file};
  $self->{abbrev} = {};
  $self->{expand} = {};
  $self->{region} = {};
  $self->{filecheck} = 0;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
