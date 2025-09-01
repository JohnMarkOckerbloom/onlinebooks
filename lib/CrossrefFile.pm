package CrossrefFile;
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
  my ($self, $description, $name) = @_;
  my $ref = {};
  $ref->{type} = "Relationship";
  $ref->{description} = $description;
  $ref->{objectname} = $name;
  return $ref;
}

sub _printref {
  my ($self, $name, $ref) = @_;
  print "$name $ref->{description} $ref->{objectname}";
  print "\n";
}

sub relationships {
  my ($self, %params) = @_;
  my @rels = ();
  my $name = $params{name};
  return @rels if (!$name);
  if ($self->{xrefs}->{$name}) {
    foreach my $nom (@{$self->{xrefs}->{$name}}) {
      push @rels, $self->_reference($RelationshipConstants::SEEALSO, $nom);
    }
  }
  #foreach my $rel (@rels) { 
  #  $self->_printref($name, $rel);
  #}
  return @rels;
}

sub _analyze_file {
  my ($self, $path, $nameheadings) = @_;
  open my $fh, "< $path" or return 0;
  while (my $line = <$fh>) {
    chomp $line;
    my @names = split /\|/, $line;
    my $len = scalar(@names);
    for (my $i = 0; $i < $len; $i++) {
      my $name1 = $names[$i];
      for (my $j = $i + 1; $j < $len; $j++) {
        my $name2 = $names[$j];
        if ($self->{oknames}->{$name1} && $self->{oknames}->{$name2}) {
          # print "$name1 relates to $name2!\n";
          push @{$self->{xrefs}->{$name1}}, $name2;
          push @{$self->{xrefs}->{$name2}}, $name1;
        }
      }
    }
  }
  close $fh;
}

sub _initialize {
  my ($self, %params) = @_;
  my $charfilepath = $params{file};
  my $namestocheck = $params{namestocheck};
  my %namehash =  map {$_ => 1} @{$namestocheck};
  $self->{oknames} = \%namehash;
  $self->{xrefs} = {};
  $self->_analyze_file($charfilepath);
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
