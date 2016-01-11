package OLBP::SubjectNode;
use strict;

sub get_parent_name {
  my ($self, %params) = @_;
  my $name = $self->{name};
  if ($name =~ /(.*\S)\s*--/) {
    return $1;
  }
  return undef;
}

# In expand, we take a string and from it
#           -- add scope notes
#           -- assign aliases
#           -- record broader terms
#           -- record related term candidates
#           -- add call number info (not there yet)

sub expand {
  my ($self, %params) = @_;
  my $str = $params{infostring};
  my @lines = split /\n/, $str;
  foreach my $line (@lines) {
    if ($line =~ /^([A-Z]+)\s+(.*)/) {
      my ($attr, $val) = ($1, $2);
      if ($attr =~ /^(SN|UF|BT|RT|NT)$/) {
        push @{$self->{$attr}}, $val;
      } elsif ($attr =~ /^(AK)$/) {
        $self->{$attr} = $val;
      }
    }
  }
}

sub scope_notes {
  my ($self, %params) = @_;
  return @{$self->{SN}};
}

sub aliases {
  my ($self, %params) = @_;
  return @{$self->{UF}};
}

sub broader_terms {
  my ($self, %params) = @_;
  return @{$self->{BT}};
}

sub related_terms {
  my ($self, %params) = @_;
  return @{$self->{RT}};
}

sub narrower_terms {
  my ($self, %params) = @_;
  return @{$self->{NT}};
}

sub author_key {
  my ($self, %params) = @_;
  return $self->{AK};
}

# this returns a list of possible shorter term that have fewer facets, if any
# (but always the last facet)
# the order is in binary terms; 0 = nothing but the last, 
# 1 = nothing but the next-to-last and last, 2= nothing but the 3rd-to-ltas
# and last, 3= third-to-last, next-to-last, last, and so on
# This is used by SubjectGraph to determine closest workable superterms

sub shorter_possibilities {
  my ($self, %params) = @_;
  my @list = ();
  my $term = $self->get_name();
  my @facets = split /\s*--\s*/, $term;
  my $numfacets = scalar(@facets);
  return () if ($numfacets < 2);
  for (my $i = 0; $i < (1 << ($numfacets - 1)) -1; $i++) { 
    my @facetlist = ();
    for (my $j = 0; $j < $numfacets - 1; $j++) { 
      if ((1 << ($numfacets - ($j+ 2))) & $i) {
         push @facetlist, $facets[$j];
      }
    }
    push @facetlist, $facets[$numfacets -1];
    push @list, join ' -- ', @facetlist;
  }
  return @list;
}

# this returns some swapping possibilities in case of mis-coordinated
# cataloging.
# We do not return *all* possible permutations (that would be n!,
# or 120 possibilities for a 5-facet term) but instead focus on
# short edit distances.
# Currently, we just consider adjacent swaps (or n-1 possibilities)

sub permuted_possibilities {
  my ($self, %params) = @_;
  my @list = ();
  my $term = $self->get_name();
  my @facets = split /\s*--\s*/, $term;
  my $numfacets = scalar(@facets);
  return () if ($numfacets < 2);
  for (my $i = 0; $i < ($numfacets - 1); $i++) { 
    my $temp = $facets[$i];
    $facets[$i] = $facets[$i+1];
    if ($i) {
      $facets[$i+1] = $facets[$i-1];
      $facets[$i-1] = $temp;
    } else {
      $facets[$i+1] = $temp;
    }
    push @list, join ' -- ', @facets;
  }
  return @list;
}

sub get_name {
  my ($self, %params) = @_;
  return $self->{name};
}

sub get_id {
  my ($self, %params) = @_;
  return $self->{id};
}

# We'll also have a simple name-setting function

sub set_name {
  my ($self, $name) = @_;
  $self->{name} = $name;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{name} = $params{name};
  $self->{id} = $params{id};
  $self->{UF} = [];
  $self->{SN} = [];
  $self->{BT} = [];
  $self->{NT} = [];
  $self->{RT} = [];
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
