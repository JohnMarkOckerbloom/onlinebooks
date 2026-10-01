package OLBP::SubjectNormalizer;
use OLBP::BookRecord;
use strict;

my $DEFAULT_SUBJECT_TYPE = "LCSUB";

sub add_normal_subject {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  my $type = $params{type} || $DEFAULT_SUBJECT_TYPE;
  # First we note each part as a valid subpart
  foreach my $part (split /\s+--\s+/, $heading) {
    my $key = OLBP::BookRecord::search_key_for_subject($part);
    if (!$self->{propersubparts}->{$key}) {
        $self->{propersubparts}->{$key} = $part;
    }
  }
  # Then we validate the subject and versions with subdivisions removed
  while ($heading) {
    my $key = OLBP::BookRecord::search_key_for_subject($heading);
    if (!$self->{propersubs}->{$key}) {
      $self->{propersubs}->{$key} = $type;
      if ($heading =~ /(.*)\s+--/) {
        $heading = $1;
      } elsif ($heading =~ /(.*)--/) {  # might not have spacing before subdiv
        $heading = $1;
      } else {
        $heading = "";
      }
    } else {
       # this and its predecessors have already been done
        $heading = "";
    }
  }
}

# If the supplied heading is a recognized normal subject, return its type
# otherwise return undef

sub normal_subject_type {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  while ($heading) {
    my $key = OLBP::BookRecord::search_key_for_subject($heading);
    if ($self->{propersubs}->{$key}) {
      return $self->{propersubs}->{$key};
    }
    if ($heading =~ /(.*)\s+--/) {
      $heading = $1;
    } else {
      last;
    }
  }
  return $DEFAULT_SUBJECT_TYPE;
}

sub _subrecord {
  my ($self, $str) = @_;
  if ($self->{subrec}->{$str}) {
   $self->{subrec}->{$str} += 1;
  } else {
   $self->{subrec}->{$str} = 1;
  }
}

sub report_subrecords {
  my ($self) = @_;
  my $report = "";
  my $subrec = $self->{subrec};
  foreach my $str (sort {$subrec->{$a} <=> $subrec->{$b}} keys %{$subrec}) {
    $report .=  $subrec->{$str} . " "  . $str ."\n";
  }
  return $report;
}

# we cache preferred (and alias) results, to minimize I/O overhead
# on repeated calls to hash's get_value

sub _check_for_preferred_value {
  my ($self, $key) = @_;
  if (!$self->{checkedprefkey}->{$key}) {
    $self->{preferredvalue}->{$key} = $self->{preferred}->get_value(key=>$key);
    # print "unchecked preferred - ";
    $self->{checkedprefkey}->{$key} = 1;
  }
  # print "checked preferred\n";
  return $self->{preferredvalue}->{$key};
}

sub _get_aliases {
  my ($self, $key) = @_;
  if (!$self->{checkedaliases}->{$key}) {
    # print "unchecked aliases - ";
    $self->{aliases}->{$key} = $self->{aliashash}->get_value(key=>$key);
    $self->{checkedaliases}->{$key} = 1;
  }
  # print "checked aliases\n";
  return $self->{aliases}->{$key};
}

sub normalized_subject {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  # we record the type of a subject, which may be reset based on
  # other instances of the subject
  my $type = "LCSUB";
  my @parts;
  # first, normalize each part
  foreach my $part (split /\s+--\s+/, $heading) {
    # the search_key normalizes case, diacritics, etc.
    my $key = OLBP::BookRecord::search_key_for_subject($part);
    # check for extraneous periods at the end of subject or subdivision
    if ($self->{propersubparts}->{$key}) {
      # if we've seen this subdivision in clean data, use that clean form
      push @parts, $self->{propersubparts}->{$key};
   } else {
     # otherwise, remove the final period unless it's preceded by a capital
     $part =~ s/([^A-Z])\.$/$1/;
     push @parts, $part;
   }
  }
  # Now, reconstitute the subject heading
  my $newname = join ' -- ', @parts;
  # And see if the name is any good, and substitute if not
  my $first = $newname;
  my $checked = "";
  while ($first) {
    my $key = OLBP::BookRecord::search_key_for_subject($first);
    if ($self->{propersubs}->{$key}) {
      # We've seen this before.  Use what we've seen (along with its type)
      $type = $self->{propersubs}->{$key};
      $checked = $first . $checked;
      $first = "";
    } elsif ($self->_check_for_preferred_value($key)) {
      # this key was found in the "preferred heading" hash index
      $checked = $first . $checked;
      $first = "";
    } else {
      my $str = $self->_get_aliases($key);
      if ($str) {
        # this key was found in the "alternate heading" hash index
        # in which the possible preferred headings appear as
        # |preferred1|preferred2|preferred3....
        my @choices = split /\|/, $str;
        shift @choices;
        if ($self->{keepsuppressed} && scalar(@choices) > 1) {
          # if keepsuppressed is true, we keep subject headings
          # that have multiple preferred headings, for logging purposes,
          # but add a "suppressed" notation that will keep it from
          # being indexed.
          $checked = "[suppressed] " . $first . $checked;
          # log what happened
          $self->_subrecord("multiple choice for $key: $str");
        } else {
          $checked = $choices[0] . $checked;
        }
        $first = "";
      }
    }
    if ($first =~ /(.*)(\s+--\s+.*)/) {
      my $next;
      ($first, $next) = ($1, $2);
      $checked = $next . $checked;
    } else {
      $checked = $first . $checked;
      $first = "";
    }
  }
  if ($newname ne $checked) {
    # log the substitution
    $self->_subrecord("$newname ==> $checked");
  }
  return $checked;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{preferred} = $params{preferred}; # preferred headings file
  $self->{aliashash} = $params{alias};     # aliased headings file
  $self->{keepsuppressed} = $params{keepsuppressed}; # if we keep suppressions
  $self->{subrec} = {};                    # for logging purposes
  $self->{propersubs} = {};                # keyed by search key for subject
  $self->{propersubparts} = {};            # keyed by search key for part
  $self->{checkedprefkey} = {};       
  $self->{preferredvalue} = {};       
  $self->{checkedaliases} = {};       
  $self->{aliases} = {};       
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

