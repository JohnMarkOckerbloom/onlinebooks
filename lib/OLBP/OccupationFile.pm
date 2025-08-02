package OLBP::OccupationFile;
use strict;

sub _read_occupations_from_file {
  my ($self, %params) = @_;
  $self->{filecheck} = 1;
  my $file = $self->{file};
  return if (!$file);
  open OCCFILE, "< $file" or return 0;
  $self->{occhash} = {};
  while (my $line = <OCCFILE>) {
    chop $line;
    my ($name, @occupations) = split /\|/, $line;
    # normalize the occupations
    my @normaloccs = ();
    $self->{occhash}->{$name} = [];
    foreach my $occ (@occupations) {
      $occ =~ s/--/ -- /g;
      $occ =~ s/\s+/ /g;
      push @{$self->{occhash}->{$name}}, $occ;
    }
  }
  close OCCFILE;
}

sub get_occupations {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  if (!$self->{occhash}) {
    $self->_read_occupations_from_file();
  }
  if (!$self->{occhash}) {
    return ();
  }
  if ($self->{occhash}->{$heading}) {
    return @{$self->{occhash}->{$heading}};
  }
  return ();
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{file} = $params{file};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
