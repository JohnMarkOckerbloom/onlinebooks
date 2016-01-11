package OLBP::HashIterator;
use OLBP::Hash;
@OLBP::HashIterator::ISA = qw(OLBP::Hash);
use strict qw(vars subs);  # Can't use strict refs with our filehandles

# Globals that really shouldn't be, but that's how it goes...

my $hashheadersize = 8;
my $hashbucketsize = 8;
my $hashlinklensize = 8;

sub wow {
   print "hi\n";
}

sub first {
  my ($self, %params) = @_;
  return (undef, undef) if ($self->{state} && $self->{state} ne "READ");
  if (!$self->{state}) {
    return undef if (!$self->_open_to_read());
  }
  my $fh = $self->_filehandle();
  my $offset = ($self->{hsize} * $hashbucketsize) + $hashheadersize;
  if (!$fh || !(seek $fh, $offset, 0)) {
    return (undef, undef);
  }
  $self->{offset} = $offset;
  return $self->next();
}

sub next {
  my ($self, %params) = @_;
  if (!$self->{offset}) {
     return $self->first();
  }
  my ($readin, $keysize, $valsize, $key, $value);  # read buffers
  my $fh = $self->_filehandle();
  if (!$fh || !(seek $fh, $self->{offset}, 0)) {
    return (undef, undef);
  }
  my $char = "*";
  my $buf = "";
  while ($char eq "*") {
    read($fh, $char, 1) or return (undef, undef);
    $self->{offset} += 1;
  }
  read($fh, $buf, $hashlinklensize-1) or return (undef,undef);
  $self->{offset} += ($hashlinklensize - 1);
  $keysize = int($char.$buf);
  read($fh, $valsize, $hashlinklensize) or return (undef,undef);
  read($fh, $key, $keysize) or return (undef,undef);
  read($fh, $value, $valsize) or return (undef,undef);
  $self->{offset} += $hashlinklensize + $keysize + $valsize;
  return ($key, $value);
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{offset} = 0;
  return $self->SUPER::_initialize(%params);
}

1;
