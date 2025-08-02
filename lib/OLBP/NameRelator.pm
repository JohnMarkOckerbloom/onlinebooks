package NameRelator;
use strict;
use CSVInput;
use RelationshipConstants;

# This file doesn't have any resource links

sub resourcelinks {
  return ();
}

# relationships returns a list of relationship refs
#
# "Associated authors" are ranked by accumulated weight of relationships
#  If we add more specific relationships later, we might remove or reweight
#  of these associations
#  Double weights for work records

my $COAUTHOR_WEIGHT            = 1;
my $EDITOR_AUTHOR_WEIGHT       = 0.5;
my $ILLUSTRATOR_AUTHOR_WEIGHT  = 0.5;
my $TRANSLATOR_AUTHOR_WEIGHT   = 0.5;
my $CONTRIBUTOR_AUTHOR_WEIGHT  = 0.1;
my $AUTHOR_SUBJECT_WEIGHT      = 0.2;

my $MAX_ASSOCIATES             = 6;

sub relationships {
  my ($self, %params) = @_;
  my @rels = ();
  my $name = $params{name};
  my $count = 0;
  return @rels if (!$name);
  # print "Looking at associated authors for $name\n";
  return @rels if (!$self->{relations}->{$name});
  my @namelist = sort {$self->{relations}->{$name}->{$b} <=>
                       $self->{relations}->{$name}->{$a}}
                      keys %{$self->{relations}->{$name}};
  # print "Found some: " . join(", ", @namelist) . "\n";
  foreach my $refname (@namelist) {
    last if ($count >= $MAX_ASSOCIATES);
    my $ref = {};
    $ref->{type} = "Relationship";
    $ref->{description} = $RelationshipConstants::ASSOCIATED;
    $ref->{objectname} = $refname;
    push @rels, $ref;
    #print "Score for $name to $refname is " .
    #   $self->{relations}->{$name}->{$refname} . "\n";
    $count += 1;
  }
  return @rels;
}

sub fatalerror {
  my ($line, $problem) = @_;
  print "Error, around line $line: $problem\n";
  exit 0;
}

sub _add_relation_score {
  my ($self, $name1, $name2, $weight) = @_;
  # print "$name1 seems related to $name2\n";
  if (!$self->{relations}->{$name1}) {
    $self->{relations}->{$name1} = {};
  }
  if (!$self->{relations}->{$name2}) {
    $self->{relations}->{$name2} = {};
  }
  if ($self->{relations}->{$name1}->{$name2}) {
    $self->{relations}->{$name1}->{$name2} += $weight;
  } else {
    $self->{relations}->{$name1}->{$name2} = $weight;
  }
  if ($self->{relations}->{$name2}->{$name1}) {
    $self->{relations}->{$name2}->{$name1} += $weight;
  } else {
    $self->{relations}->{$name2}->{$name1} = $weight;
  }
}

sub _score_relations {
  my ($self, $br) = @_;
  my @names = $br->get_names();
  my @roles = $br->get_roles();
  for (my $i = 0; $i < scalar(@names); $i++) {
    for (my $j = $i + 1; $j < scalar(@names); $j++) {
      # print "Comparing $names[$i] ($roles[$i]) with $names[$j] ($roles[$j])\n";
      my $weight = 0;
      if (($roles[$i] eq "AUTHOR" && $roles[$j] eq "AUTHOR")  ||
          ($roles[$i] eq "EDITOR" && $roles[$j] eq "EDITOR")) {
        $weight = $COAUTHOR_WEIGHT;
      } elsif (($roles[$i] eq "AUTHOR" && $roles[$j] eq "EDITOR")  ||
               ($roles[$i] eq "EDITOR" && $roles[$j] eq "AUTHOR")) {
        $weight = $EDITOR_AUTHOR_WEIGHT;
      } elsif (($roles[$i] eq "AUTHOR" && $roles[$j] eq "ILLUSTRATOR")  ||
               ($roles[$i] eq "ILLUSTRATOR" && $roles[$j] eq "AUTHOR")) {
        $weight = $ILLUSTRATOR_AUTHOR_WEIGHT;
      } elsif (($roles[$i] eq "AUTHOR" && $roles[$j] eq "TRANSLATOR")  ||
               ($roles[$i] eq "TRANSLATOR" && $roles[$j] eq "AUTHOR")) {
        $weight = $TRANSLATOR_AUTHOR_WEIGHT;
      } elsif (($roles[$i] eq "AUTHOR" && $roles[$j] eq "CONTRIBUTOR")  ||
               ($roles[$i] eq "CONTRIBUTOR" && $roles[$j] eq "AUTHOR")) {
        $weight = $CONTRIBUTOR_AUTHOR_WEIGHT;
      }
      if ($br->is_work()) {
        $weight *= 2;
      }
      if ($weight) {
        $self->_add_relation_score($names[$i], $names[$j], $weight);
      }
    }
  }
  # TODO: Add additional pass for author-(name?) subject relations
  #  (need to get those somehow, and only relate when one is listed as author)
}

sub _addscores {
  my ($self, $recstring) = @_;
  my $br = new OLBP::BookRecord(string=>$recstring);

  if (!$br) {
    print "Didn't like:\n $recstring\n";
    fatalerror $., OLBP::BookRecord::get_format_error();
  }
  # we only need to remember work records
  if ($br->is_work()) {
    my $id = $br->get_id();
    $self->{workrecs}->{$id} = $br;
  }
  # don't forget to add inherited names and subjects if applicable
  my $wid = $br->get_work();
  if ($wid) {
    my $work = $self->{workrecs}->{$wid};
    if ($work) {
      $br->inherit(from=>$work);
    }
  }
  $self->_score_relations($br);
}

sub _readbooks {
  my ($self, $bookfile) = @_;
  my $recstring;
  my $line;
  open BOOKS, $bookfile or die "Can't open $bookfile";
  while ($line = <BOOKS>) {
    next if ($line =~ /^#/);
    if ($line =~ /^\s*$/) {
      if ($recstring) {
        $self->_addscores($recstring);
        $recstring = "";
      }
      $recstring = "";
    } elsif (!($line =~ /^[A-Z]+\+?\s+/)) {
      fatalerror $., "Unrecognized data line: $line";
    } else {
      $recstring .= $line;
    }
  }
  close BOOKS;
}

sub _initialize {
  my ($self, %params) = @_;
  my $bookfilepath = $params{file};
  $self->{workrecs} = {};
  $self->{relations} = {};
  $self->_readbooks($bookfilepath);
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
