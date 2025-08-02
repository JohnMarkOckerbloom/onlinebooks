package PennPeopleFile;
use strict;
use CSVInput;

my $pennfilepath = "/home/ockerblo/bibdata/references/pennpeople.csv";

sub _namesmatch {
  my ($namestr, $pennname) = @_;
  # get rid of last names if any
  $namestr =~ s/[^,]+,\s+//;
  $pennname =~ s/[^,]+,\s+//;
  my @pennwords = split /\W+/, $pennname;
  foreach my $word (@pennwords) {
    return 0 if (index($namestr, $word) < 0);
  }
  return 1;
}

# returns the number of the row with the supplied parameters, or
# or undef if none found

sub _findrownum {
  my ($self, %params) = @_;
  my $name = $params{name};
  my $lastname = $name;
  if ($name =~ /([^,]+),/) {
    $lastname = $1;
  } else {
    $lastname =~ s/.*\s+//;
  }
  if ($self->{lastrows}->{$lastname}) {
    # last name matched
    foreach my $rownum (@{$self->{lastrows}->{$lastname}}) {
      # each word in Penn People name should also be in supplied name
      my $pennname = $self->{lines}->[$rownum]->{"Name"};
      # print "Does $name match the Penn people entry for $pennname?\n";
      next if (!_namesmatch($name, $pennname));
      my $pennlifedates = $self->{lines}->[$rownum]->{"Lifespan"};
      # first and last dates in supplied name should be in Penn people row
      if ($name =~ /(\d\d\d\d)/) {
        my $firstdate = $1;
        next if (index($pennlifedates, $firstdate) < 0);
      } else {
        next; # false positives too likely if supplied name has no dates
      }
      if ($name =~ /.*(\d\d\d\d)/) {
        my $lastdate = $1;
        next if (index($pennlifedates, $lastdate) < 0);
      }
      # print "$name and $pennname matched\n";
      return $rownum;
    }
  }
  return undef;
}

# resourcelinks returns a list of resource refs
# this one will return a list with
#  a hash with a URL and the description "Penn People biography"
# if the name matches

sub resourcelinks {
  my ($self, %params) = @_;
  my $rownum = $self->_findrownum(%params);
  if ($rownum) {
    my $ref = {};
    $ref->{url} = $self->{lines}->[$rownum]->{"Link"};
    $ref->{note} = "Penn People biography";
    # print " ($ref->{url})!\n";
    my @reflist = ($ref);
    return @reflist;
  }
  return ();
}

# relationships returns a list of relationship refs
# this one will return a list with
#  a hash with a Upenn QID, a description, and a date or date range
# if the name matches

sub _addpenninfo {
  my ($ref) = @_;
  $ref->{type} = "Role";
  $ref->{objectname} = "University of Pennsylvania";
  $ref->{objectqid} = "Q49117";
}

sub _printref {
  my ($ref) = @_;
  print " $ref->{description}, $ref->{objectname}";
  if ($ref->{date1}) {
    print " ($ref->{date1} - $ref->{date2})";
  } elsif ($ref->{date}) {
     print " ($ref->{date1})";
  } 
  print "\n";
}

sub relationships {
  my ($self, %params) = @_;
  my @rels = ();
  my $rownum = $self->_findrownum(%params);
  if ($rownum) {
    my $connectionstr = $self->{lines}->[$rownum]->{"Penn Connection"};
    if ($connectionstr =~ /Founder and [Tt]rustee/) {
      # other founders in the file weren't founders of the university itself
      my $ref = {"description" => "Founder"};
      _addpenninfo($ref);
      push @rels, $ref;
      # _printref($ref);
    }
    while ($connectionstr =~ /[Tt]rustee\b(\s+[\d\s\-]+)?(.*)/) {
      my ($range, $rest) = ($1, $2);
      my $ref = {"description" => "Trustee"};
      _addpenninfo($ref);
      if ($range =~ /(\d\d\d\d)\s*\-\s*(\d\d\d\d)/) {
        $ref->{date1} = $1;
        $ref->{date2} = $2;
      } elsif ($range =~ /(\d\d\d\d)/) {
        $ref->{date} = $1;
      }
      push @rels, $ref;
      # _printref($ref);
      $connectionstr = $rest;
    }
  }
  return @rels;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{csv} = Text::CSV->new ({ binary => 1, auto_diag => 1 });
  my $pennfilepath = $params{file},
  my $csv = new CSVInput(filename=>$pennfilepath);
  $self->{lines} = $csv->get_rows();
  my @csvlines = @{$self->{lines}};
  $self->{lastrows} = {};
  for (my $i = 0; $csvlines[$i]; $i++) {
    my $name = $csvlines[$i]->{"Name"};
    if ($name =~ /([^,]+),/) {
      my $last = $1;
      push @{$self->{lastrows}->{$last}}, $i;
      # print "$last appears on row $i\n";
    }
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
