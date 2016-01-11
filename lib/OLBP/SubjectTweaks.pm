package OLBP::SubjectTweaks;
use strict;

sub _read_tweaks {
  my ($self, %params) = @_;
  $self->{filecheck} = 1;
  my $file = $self->{file};
  return if (!$file);
  my $key = 0;
  open TWEAK, "< $file" or return 0;
  while (my $line = <TWEAK>) {
    if (!($line =~ /\S/)) {
      $key = "";
    } elsif ($key) {
      $self->{tweakstr}->{$key} .= $line;
    } else {
      $key = $line;
      chop $key;
      $key = OLBP::BookRecord::search_key_for_subject($key);
    }
  }
  close TWEAK;
}

sub get_tweak_string {
  my ($self, %params) = @_;
  my $key = $params{key};
  if (!$key) {
    my $name = $params{heading};
    $key = OLBP::BookRecord::search_key_for_subject($name);
  }
  return 0 if (!$key);
  if (!$self->{filecheck}) {
    $self->_read_tweaks();
  }
  return $self->{tweakstr}->{$key};
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{file} = $params{file};
  $self->{tweakstr} = {};
  $self->{filecheck} = 0;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
