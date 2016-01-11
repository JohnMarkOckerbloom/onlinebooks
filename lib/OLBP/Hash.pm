package OLBP::Hash;
use strict qw(vars subs);  # Can't use strict refs with our filehandles

# Globals that really shouldn't be, but that's how it goes...

my $hashheadersize = 8;
my $hashbucketsize = 8;
my $hashlinklensize = 8;

sub hash {
  my ($self, $str, $size) = @_;
  my $hashint = 1;
  foreach my $c (split //, $str) {
    $hashint = (($hashint * 9) + ord($c)) % $size;
  }
  return $hashint;
}

sub _filehandle {
  my ($self, %params) = @_;
  return $self->{name} . "HFH";
}

sub _open_to_read {
  my ($self, %params) = @_;
  my $name = $self->{name};
  my $filename = $self->{filename};
  my $numbuckets;
  my $hashheadersize = 8;
  my $fh = $self->_filehandle();
  open ($fh, "< $filename") or return 0;
  read $fh, $numbuckets, $hashheadersize;
  if ($numbuckets =~ /^x(.*)/) {
    $self->{hexoffset} = 1;
    $self->{hsize} = int(hex($1));
  } else {
    $self->{hsize} = int($numbuckets);
  }
  $self->{state} = "READ";
  return 1;
}

sub get_value {
  my ($self, %params) = @_;
  my $key = $params{key};
  return undef if ($self->{state} && $self->{state} ne "READ");
  if (!$self->{state}) {
    return undef if (!$self->_open_to_read());
  }
  my $keyhash = $self->hash($key, $self->{hsize});
  my $fh = $self->_filehandle();
  if (!$fh || !(seek $fh, $hashheadersize + ($keyhash * $hashbucketsize), 0)) {
    return undef;
  }
  my ($readin, $keysize, $valsize, $keycand);  # read buffers
  read $fh, $readin, $hashbucketsize;
  my $offset = int($readin);
  if ($self->{hexoffset}) {
    $offset = int(hex($readin));
  }
  return undef if (!$offset);
  return undef if (!seek $fh, $offset, 0);
  while (1) {
    read($fh, $keysize, $hashlinklensize) or return undef;
    return undef if (!int($keysize) || ($keysize =~ /^\*/));
    read($fh, $valsize, $hashlinklensize) or return undef;
    read($fh, $keycand, $keysize) or return undef;
    if ($keycand eq $key) {
      read $fh, $readin, $valsize;
      return $readin;
    } else {
      seek($fh, $valsize, 1) or return undef;
    }
  }
}

# numbers here are 8-digit decimal by default, for portability, which 
# imposes a 100MB limit on the packed hash file size (and 100M buckets)
# if the hexoffset property is set on the object, though, offset numbers
# are recorded as 8-digit hexadecimal, which brings the maximum
# size up to over 4 GB, and the max number of buckets to over 200M.
# Don't get carried away with this, though; remember, we're building
# the entire hash in memory when we pack it.

sub pack_to_file {
  my ($self, %params) = @_;
  my $filename = $self->{filename};
  my $hashref = $params{hash};
  my $hashsize = $params{hashsize};
  my ($key, $val);
  my @harray;
  my $i;
  my $len;
  if (!$hashsize) {
    $hashsize = 2 * scalar(keys %{$hashref});
  }
  $#harray = $hashsize;
  while (($key, $val) = each %{$hashref}) {
    my $hashint = $self->hash($key, $hashsize);
    $harray[$hashint] .=
        sprintf("%08d%08d%s%s", length($key), length($val), $key, $val);
  }
  my $fh = $self->_filehandle();
  open $fh, "> $filename" or return undef;
  if ($self->{hexoffset}) {
    print $fh sprintf("x%07x", $hashsize);
  } else {
    print $fh sprintf("%08d", $hashsize);
  }
  my $offset = 8 * $hashsize + 8;                   # each row + header
  for ($i = 0; $i < $hashsize; $i++) {
    if (!$harray[$i]) {
      print $fh sprintf("%08d", 0);
    } else {
      $len = length($harray[$i]) + 1; # don't forget hash bucket end marker
      if ($self->{hexoffset}) {
        print $fh sprintf("%08x", $offset);
      } else {
        print $fh sprintf("%08d", $offset);
      }
      $offset += $len;
    }
  }
  for ($i = 0; $i < $hashsize; $i++) {
    if ($harray[$i]) {
      print $fh $harray[$i],  "*";
    }
  }
  close $fh;
  return 1;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{name} = $params{name};
  $self->{filename} = $params{filename};
  $self->{hexoffset} = $params{hexoffset};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


