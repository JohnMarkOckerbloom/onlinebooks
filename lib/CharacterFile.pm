package CharacterFile;
use strict;
use CSVInput;
use RelationshipConstants;

# This file doesn't have any resource links

sub resourcelinks {
  return ();
}

# relationships returns a list of relationship refs
# this one will return a list with
#  a hash with a Upenn QID, a description, and a date or date range
# if the name matches

sub _reference {
  my ($self, $description, $qid) = @_;
  my $ref = {};
  $ref->{type} = "Relationship";
  $ref->{description} = $description;
  $ref->{objectqid} = $qid;
  # $ref->{objectname} = $self->{label}->{$qid};
  $ref->{objectname} = $self->{idheadings}->{$qid};
  return $ref;
}

sub _printref {
  my ($self, $qid, $ref) = @_;
  # print $self->{label}->{$qid};
  print $self->{idheadings}->{$qid};
  print " $ref->{description} $ref->{objectname}";
  print "\n";
}

sub relationships {
  my ($self, %params) = @_;
  my @rels = ();
  my $qid = $params{qid};
  return @rels if (!$qid);
  if ($self->{characters}->{$qid}) {
    foreach my $char (@{$self->{characters}->{$qid}}) {
      push @rels, $self->_reference($RelationshipConstants::CREATED, $char);
    }
  }
  if ($self->{creators}->{$qid}) {
    foreach my $creator (@{$self->{creators}->{$qid}}) {
      push @rels,
             $self->_reference($RelationshipConstants::CREATEDBY, $creator);
    }
  }
  #foreach my $rel (@rels) { 
  #  $self->_printref($qid, $rel);
  #}
  return @rels;
}

sub _analyze_lines {
  my ($self, $idheadings, @csvlines) = @_;
  $self->{label} = {};
  $self->{characters} = {};
  $self->{creators} = {};
  $self->{idheadings} = $idheadings;
  foreach my $line (@csvlines) {
    my $character = $line->{character};
    my $creator = $line->{creator};
    $character =~ s/.*Q/Q/;                   # strip down to just the QID
    $creator =~ s/.*Q/Q/;                     
    if ($character && $creator) {
      if ($idheadings->{$character} && $idheadings->{$creator}) {
        push @{$self->{characters}->{$creator}}, $character;
        push @{$self->{creators}->{$character}}, $creator;
        # print "$creator created $character\n";
      }
    }
  }
}

sub _initialize {
  my ($self, %params) = @_;
  my $charfilepath = $params{file};
  my $idheadings = $params{idheadings};
  my $csv = new CSVInput(filename=>$charfilepath);
  my @csvlines = @{$csv->get_rows()};
  $self->_analyze_lines($idheadings, @csvlines);
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
