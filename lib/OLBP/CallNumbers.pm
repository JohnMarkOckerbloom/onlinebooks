package OLBP::CallNumbers;
use strict qw(vars subs);  # Can't use strict refs with our filehandles

sub read_calls {
  my $line;
  my $callr;
  my ($self, %params) = @_;
  open CALLS, $self->{filename} or return 0;
  while ($line = <CALLS>) {
    next if ($line =~ /^#/);
    if ($line =~ /^([A-Z]\S*)\s+(.*)/) {
      $callr = {};
      $callr->{range} = $1;
      $callr->{title} = $2;
      if ($callr->{range} =~ /(.*)-(.*)/) {
        $callr->{leftsort} = OLBP::BookRecord::sort_key_for_lccn($1);
        $callr->{rightsort} = OLBP::BookRecord::sort_key_for_lccn($2);
      } else {
        $callr->{leftsort} =
          OLBP::BookRecord::sort_key_for_lccn($callr->{range});
        $callr->{rightsort} = $callr->{leftsort};
      }
      push @{$self->{calls}}, $callr;
    } elsif ($line =~ /^\*\s*(.*)/ && $callr) {
      push @{$callr->{notes}}, $1;
    }
  }
  close CALLS;
  return 1;
}

sub inorafter {
  my ($self, $lccnsorted, $index) = @_;
  my $callr = $self->{calls}->[$index];
  return 0 if (!$callr);
  my $left = $callr->{leftsort};
  return 0 if (!$left || ($lccnsorted lt $left));
  return 1;
}

sub inrange {
  my ($self, $lccnsorted, $index) = @_;
  my $callr = $self->{calls}->[$index];
  return 0 if (!$callr);
  my $left = $callr->{leftsort};
  my $right = $callr->{rightsort};
  return 0 if (!$left || !$right || ($lccnsorted lt $left));
  return 1 if ($lccnsorted le $right);
  return 1 if (substr($lccnsorted, 0, length($right)) eq $right); 
  return 0;
}

# returns the index of the next call number range for this
# cursor that contains the sorted LCCN fed in, or undef if there isn't 
# one yet

sub next_callrange {
  my ($self, %params) = @_;
  my $lccn = $params{sortedlccn};
  my $cursor = $params{cursor};
  return undef if (!$lccn || !defined($cursor));
  my $pos = $self->{cursors}->[$cursor] + 1;
  while ($self->inorafter($lccn, $pos)) {
    if ($self->inrange($lccn, $pos)) {
      $self->{cursors}->[$cursor] = $pos;
      return $pos;
    }
    $pos++;
  }
  return undef;
}

sub get_callr {
  my ($self, %params) = @_;
  my $callr;
  my $index = undef;
  if (defined($params{index})) {
    $index = $params{index};
  } elsif (defined($params{cursor})) {
    $index = $self->{cursors}->[$params{cursor}];
  }
  if (defined($index)) {
    $callr = $self->{calls}->[$index];
  }
  return $callr;
}

sub get_range {
  my ($self, %params) = @_;
  my $callr = $self->get_callr(%params); 
  if ($callr) {
    return $callr->{range};
  }
}

sub get_title {
  my ($self, %params) = @_;
  my $callr = $self->get_callr(%params); 
  if ($callr) {
    return $callr->{title};
  }
}

sub get_notes {
  my ($self, %params) = @_;
  my $callr = $self->get_callr(%params); 
  if ($callr && $callr->{notes}) {
    return @{$callr->{notes}};
  }
  return ();
}


sub new_cursor {
  my ($self, %params) = @_;
  $self->{cursors}->[$self->{nextcursor}] = -1;
  $self->{nextcursor} += 1;
  return $self->{nextcursor} - 1;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{filename} = $params{filename};
  $self->{calls} = [];
  $self->{cursors} = [];
  $self->{nextcursor} = 0;
  return 0 if (!$self->{filename});
  return 0 if (!$self->read_calls());
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}



1;


