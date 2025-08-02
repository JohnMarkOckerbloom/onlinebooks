package CSVInput;
use strict;
use Text::CSV;

my $csv = Text::CSV->new ( { binary => 1, auto_diag => 1  } ) 
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();

sub _read_csvfile {
  my ($self, $fname, $encoding) = @_;
  my @results;
  open my $fh, "<:encoding($encoding)", $fname or return 0;
  $csv->eof or $csv->error_diag();
  my @fieldnames;
  my $first = 1;
  while (my $row = $csv->getline ($fh)) {
    if ($self->{skiplines} && $self->{skiplines} > 0) {
      $self->{skiplines} -= 1;
      next;
    }
    my @fields = @{$row};
    # print "got a row with fields " . join( ":", @fields) . "\n";
    if ($first) {
      # some CSV files start with a byte-order-marker: remove if so
      if ($fields[0] =~ /\x{feff}(.*)/) { 
        $fields[0] = $1;
      }
      @fieldnames = @fields;
      $first = 0;
    } else {
      my %hash = ();
      for (my $i = 0; $i < scalar(@fields); $i++) {
        # print "putting $fields[$i] into $fieldnames[$i]\n";
        $hash{$fieldnames[$i]} = $fields[$i];
      }
      push @results, \%hash;
    }
  }
  $csv->eof or $csv->error_diag();
  close $fh;
  $self->{contents} = \@results;
  $self->{fieldnames} = \@fieldnames;
  $self->{contentread} = 1;
  return @results;
}

sub get_fieldnames {
  my ($self, %params) = @_;
  if (!$self->{contentread}) {
    $self->_read_csvfile($self->{filename}, $self->{encoding});
  }
  if ($self->{fieldnames}) {
    return @{$self->{fieldnames}};
  }
  return ();
}

sub get_rows {
  my ($self, %params) = @_;
  if (!$self->{contentread}) {
    $self->_read_csvfile($self->{filename}, $self->{encoding});
  }
  return $self->{contents};
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{filename} = $params{filename};
  $self->{encoding} = $params{encoding} || "utf8";
  $self->{contents} = 0;
  $self->{contentread} = 0;
  $self->{skiplines} = $params{skiplines};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

