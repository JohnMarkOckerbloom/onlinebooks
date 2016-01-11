package OLBP::Index;
use strict qw(vars subs);  # Can't use strict refs with our filehandles

sub _filehandle {
  my ($self, %params) = @_;
  return $self->{name} . "IFH";
}

sub _open_to_read {
  my ($self, %params) = @_;
  my $name = $self->{name};
  my $filename = $self->{filename};
  my $fh = $self->_filehandle();
  open ($fh, "< $filename") or return 0;
  my $firstline = <$fh>;
  $self->{firstline_offset} = length($firstline);
  ($self->{arraysize}, $self->{keywidth}, $self->{valuewidth}) =
      split / /, $firstline;
  $self->{state} = "READ";
  return 1;
}

sub get_size {
  my $self = shift;
  if (!$self->{state}) {
    if (!$self->_open_to_read()) {
      return 0;
    }
  }
  return $self->{arraysize};
}

sub get_slot {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my $cache = $self->{cache};

  return undef if ($self->{state} && $self->{state} ne "READ");
  if (!$self->{state}) {
    return undef if (!$self->_open_to_read());
  }
  if ($cache) {
    if ($self->{keycache}->{$idx}) {
      return ($self->{keycache}->{$idx}, $self->{valcache}->{$idx});
    }
  }
  my $fh = $self->_filehandle();
  my $slotsize = $self->{keywidth} + $self->{valuewidth};
  my $slot;

  return undef if ($idx < 0 || $idx > $self->{arraysize});
  if (!$fh || !(seek $fh, $self->{firstline_offset} + ($idx * $slotsize), 0)) {
    return undef;
  }
  read $fh, $slot, $slotsize;
  my ($key, $val) = unpack("a$self->{keywidth}a$self->{valuewidth}", $slot);
  $key =~ s/\0+$//;
  $val =~ s/\0+$//;
  if ($cache) {
    ($self->{keycache}->{$idx}, $self->{valcache}->{$idx}) = ($key, $val);
  }
  return ($key, $val);
}

# closest_index returns the first array element (in a sorted
# array) starting with the prefix (or the first one after that, if
# there is no start)

sub closest_index {
  my ($self, %params) = @_;
  my $key = $params{key};
  return undef if ($self->{state} && $self->{state} ne "READ");
  if (!$self->{state}) {
    return undef if (!$self->_open_to_read());
  }
  my $keylen = length($key);
  my $gt = -1;
  my $lt = $self->{arraysize};
  return undef if (!$lt || $lt <= $gt);

  my ($found, $thename, $theval);

  while ($gt + 1 < $lt) {
    my $midpoint = int(($lt - $gt) / 2) + $gt;
    ($thename, $theval) = $self->get_slot(index=>$midpoint);
    if (substr($thename, 0, $keylen) eq $key) {
      $found = $lt = $midpoint;
    } elsif ($thename gt $key) {
      $lt = $midpoint;
    } else {              # key must be gt $thename
      $gt = $midpoint;
    }
  }
  if ($found) {
    return $found;
  }
  return $lt;
}

sub open_to_write {
  my ($self, %params) = @_;
  my $name = $self->{name};
  my $filename = $self->{filename};
  $self->{arraysize} = $params{size};
  $self->{keywidth} = $params{keywidth};
  $self->{valuewidth} = $params{valuewidth};
  my $fh = $self->_filehandle();
  return undef if (!$filename || !$self->{arraysize}
                   || !$self->{keywidth} || !$self->{valuewidth});
  open ($fh, "> $filename") or return undef;
  print $fh "$self->{arraysize} $self->{keywidth} $self->{valuewidth}\n";
  $self->{state} = "WRITE";
  return 1;
}

sub write_item {
  my ($self, %params) = @_;
  my $key = $params{key};
  my $value = $params{value};
  my $fh = $self->_filehandle();
  # print "key is $key, value is $value\n";
  # print "keywidth is $self->{keywidth}, value is $self->{valuewidth}\n";
  print $fh pack("a$self->{keywidth}", $key);
  print $fh pack("a$self->{valuewidth}", $value);
  $self->{count}++;
}

sub close_write {
  my ($self, %params) = @_;
  close $self->_filehandle() or return 0;
  $self->{state} = "";
  if ($self->{count} != $self->{arraysize}) {
    print STDERR "Error: Index opened with size $self->{arraysize} " .
                 " but wrote $self->{count}\n";
    return 0;
  }
  $self->{state} = "";
  return 1;
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{name} = $params{name};
  $self->{filename} = $params{filename};
  $self->{cache} = $params{cache};
  $self->{keycache} = {};
  $self->{valcache} = {};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


