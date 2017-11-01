package OLBP::AuthorRights;
use strict;

sub rights_url {
  my ($self, %params) = @_;
  my $id = $params{id};
  return $self->{url}->{$id};
}

sub _read_file {
  my ($self) = @_;
  open my $fh, "< $self->{path}" or return undef;
  while (<$fh>) {
    next if /^#/;
    if (/^(\S+)\s+(\S+)/) {
      $self->{url}->{$1} = $2;
    }
  }
  close $fh;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{path} = $params{path};
  $self->{url} = {};
  $self->_read_file;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

