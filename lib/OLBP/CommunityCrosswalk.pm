package OLBP::CommunityCrosswalk;
use strict;

sub _in_range {
  my ($leftkey, $rightkey, $candidate) = @_;
  if (!$rightkey) {
    $rightkey = $leftkey;
  }
  return 0 if (!$leftkey || ($candidate lt $leftkey));
  return 1 if ($candidate le $rightkey);
  return 1 if (substr($candidate, 0, length($rightkey)) eq $rightkey);
  return 0;
}

sub _lccnkeys {
  my $range = shift;
  if ($range =~ /(.*)-(.*)/) {
    return (OLBP::BookRecord::sort_key_for_lccn($1),
            OLBP::BookRecord::sort_key_for_lccn($2));
  }
  my $key = OLBP::BookRecord::sort_key_for_lccn($range);
  return ($key, $key);
}

sub _read_inmap {
  my ($self, %params) = @_;
  $self->{mapfilecheck} = 1;
  return 0 if (!$self->{mapfile});
  open IN, "< $self->{mapfile}" or return 0;
  while (my $line = <IN>) {
    my @bits = split /\|/, $line;
    my $commname = $bits[0];
    my $commcalls = $bits[1];
    my $commstrs = $bits[2];
    if ($commcalls) {
      my @callranges = split /,/, $commcalls;
      foreach my $range (@callranges) {
        # Mike tells me 5 digits implies a decimal point before the last
        $range =~ s/(\d\d\d\d)(\d)/$1.$2/g;
        if ($range =~ /^([A-Z]*)\s+$/) {
          $range = $1 . "1-" . $1 . "999999";
        } else {
          $range =~ s/\s+//g;
        }
        my ($leftkey, $rightkey) = _lccnkeys($range);
        push @{$self->{community}->{$commname}->{range}}, $range;
        push @{$self->{community}->{$commname}->{lccnleft}}, $leftkey;
        push @{$self->{community}->{$commname}->{lccnright}}, $rightkey;
      }
    }
    if ($commstrs) {
      my @strings = split /,/, $commstrs;
      foreach my $string (@strings) {
        if ($string) {
          push @{$self->{community}->{$commname}->{string}}, $string;
        }
      }
    }
  }
  close IN;
  return 1;
}

sub getcommunities {
  my ($self, %params) = @_;
  my $call = $params{call};
  my $key = $params{key};
  if (!$key) {
    $key = $params{term};
    $key = lc($key);
    $key =~ s/[^a-z ]//g;
  }
  my @commlist;
  my @calllist;
  if (!$self->{mapfilecheck}) {
    $self->_read_inmap();
  }
  return () if (!$self->{community});
  if ($call) {
    @calllist = ($call);
    if (ref($call)) {
      @calllist = @{$call};
    }
  }
  NAME: foreach my $name (keys %{$self->{community}}) {
    if ($key && $self->{community}->{$name}->{string}) {
      foreach my $string (@{$self->{community}->{$name}->{string}}) {
        if (index($key, $string) >= 0) {
          push @commlist, $name;
          next NAME;
        }
      }
    }
    if (scalar(@calllist) && $self->{community}->{$name}->{range}) {
      # we consider there to be a match if any of the call number
      # ranges of the subject are completely within any of the call
      # number ranges of the community
      for (my $i = 0; $self->{community}->{$name}->{lccnleft}->[$i]; $i++) {
        my $commleft = $self->{community}->{$name}->{lccnleft}->[$i];
        my $commright = $self->{community}->{$name}->{lccnright}->[$i];
        foreach my $subrange (@calllist) {
          my ($subleft, $subright) = _lccnkeys($subrange);
          if (_in_range($commleft, $commright, $subleft) &&
              _in_range($commleft, $commright, $subright)) {
            push @commlist, $name;
            next NAME;
          }
        }
      }
    }
  }
  return @commlist;
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{community} = {};
  $self->{mapfile} = $params{mapfile};
  $self->{mapfilecheck} = 0;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
