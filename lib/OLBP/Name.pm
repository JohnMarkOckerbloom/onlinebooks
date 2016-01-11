package OLBP::Name;
use strict;

# helper method to ignore date suffixes on single-part names
# (see below)
# date suffixes we recognize consist just of digits and dashes
# or digits-digits B.C.  
#
# More complex date suffixes aren't recongized, so informal names
# for one-word names with more complex date suffixes may need to be
# explicitly specified.

sub _isdatesuffix {
  my $s = shift;
  return (($s =~ /^[-\d\s]*$/) || ($s =~ /^\s*\d*-\d*\s+B\.\s*C\.\s*$/));
}

# informal gives an informal name suitable for printing
# takes either a name string or an object
# For strings, it's assumed to be either
# -- if a |* exists in the string, the part after that
#     (or the part before that if nothing's after that)
# -- otherwise, the second part (part between first comma and next
#     comma, bracket, or parenthesis, followed by a space, followed by
#     the part before the first comma
#    e.g. "Walpole, Hugh, Sir, 1884-1941" -> "Hugh Walpole"
#     but if the second part is a date suffix, just throw it out
#    (e.g. "Voltaire, 1694-1778" -> "Voltaire", not "1694-1778 Voltaire")


sub informal {
  my $name = shift;
  if (ref($name)) {                     # informal name in the object
    return $name->{informal};
  }
  if ($name =~ /^\[(\w*)]\s+(.*\S)/) {  # discard wdb ref if any
    my $wdbref;
    ($wdbref, $name) = ($1, $2);
  }
  if ($name =~ /(.*)\|\*\s*(.*)/) {     # explicitly declared informal names
    return ($2 || $1);
  }
  if ($name =~ /^([^,]+),\s+(.+)/) {    # construct the informal name
    $name = $1;
    my $s2 = $2;
    if (_isdatesuffix($s2)) {
      $s2 = "";
    } elsif ($s2 =~ /([^,(\[]*)[,(\[]/) {
      $s2 = $1;
      $s2 =~ s/\s+$//;
    }
    if ($s2) {
      $name = $s2 . " " . $name;
    }
  }
  return $name;
}

sub wdbref {
  my $name = shift;
  if (ref($name)) {                     # wdbref in the object
    return $name->{wdbref};
  }
  if ($name =~ /^\[(\w*)]\s+(.*\S)/) {  # wdbref in the name
    return $1;
  }
  return undef;
}

sub formal {
  my $name = shift;
  if (ref($name)) {                     # formal in the object
    return $name->{formal};
  }
  if ($name =~ /^\[(\w*)]\s+(.*\S)/) {  # strip wdbref
    $name = $2;
  }
  if ($name =~ /(.*)\|\*/) {            # strip informal declaration
    $name = $1;
  }
  return $name;
}

# Some possibly useful derived methods

# naive just returns the name you'd get from doing a simple inversion
# (after the first comma, if any) on the informal name.
# May be useful to compare against the real informal name in some cases.

sub naive {
  my $name = shift;
  my $str = formal($name);
  if ($str =~ /^([^,]+),\s+(.+)/) {
    return "$2 $1";
  }
  return $str;
}

# Object methods

sub _initialize {
  my ($self, %params) = @_;
  my $str = $params{string};
  if ($str) {
    $self->{formal} = formal($str);
    $self->{informal} = informal($str);
    $self->{wdbref} = wdbref($str);
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
