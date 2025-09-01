package OLBP::AuthorNote;
use strict;
use OLBP::Entities;

sub get_aliases {
  my ($self, %params) = @_;
  return @{$self->{alias}};
}

sub get_formal_name {
  my ($self, %params) = @_;
  return $self->{formalname};
}

sub get_informal_name {
  my ($self, %params) = @_;
  return $self->{informalname};
}

sub num_books_about {
  my ($self, %params) = @_;
  return scalar(@{$self->{subject}});
}

# returns a list of any names mentioned in see also notes

sub get_xrefs {
  my ($self, %params) = @_;
  my @xrefs = ();
  if ($self->{note}) {
    foreach my $note (@{$self->{note}}) {
      if ($note =~ /[Ss]ee also\s+(.*)/) {
        push @xrefs, $1;
      }
    }
  }
  return @xrefs;
}

# returns any notes that don't appear to be see also links

sub get_misc_notes {
  my ($self, %params) = @_;
  my @comments = ();
  if ($self->{note}) {
    foreach my $note (@{$self->{note}}) {
      if (!($note =~ /see /)) {
        push @comments, $note;
      }
    }
  }
  return @comments;
}

sub parse {
  my ($self, %params) = @_;
  my $str = $params{string};
  my @lines = split /\n/, $str;
  foreach my $line (@lines) {
    if ($line =~ /^NAME\s+(.*)/) {
      $self->{formalname} = $1;
    } elsif ($line =~ /^INFORMAL\s+(.*)/) {
      $self->{informalname} = $1;
    } elsif ($line =~ /^ALIAS\s+(.*)/) {
      push @{$self->{alias}}, $1;
    } elsif ($line =~ /^NOTE\s+(.*)/) {
      push @{$self->{note}}, $1;
    } elsif ($line =~ /^SUBIN\s+(.*)/) {
      my $subject = $1;
      my $subjtype = "";
      if ($subject =~ /(.*)\s*|\s*(.*)/) {
        ($subjtype, $subject) = ($1, $2);
      }
      push @{$self->{subject}}, $subject;
      push @{$self->{subjtype}}, $subjtype;
    }
  }
}

sub unparse {
  my ($self, %params) = @_;
  my $str;
  if ($self->{formalname}) {
    $str .= "NAME $str->{formalname}\n";
  }
  if ($self->{informalname}) {
    $str .= "INFORMAL $str->{informalname}\n";
  }
  if ($self->{alias}) {
    foreach my $alias (@{$self->{alias}}) {
      $str .= "ALIAS $alias\n";
    }
  }
  if ($self->{note}) {
    foreach my $note (@{$self->{note}}) {
      $str .= "NOTE $note\n";
    }
  }
  if ($self->{subject}) {
    for (my $i = 0; $self->{subject}->[$i]; $i++) {
      $str .= "SUBIN ";
      if ($self->{subjtype}->[$i]) {
        $str .= $self->{subjtype}->[$i] . "|";
      }
      $str .= $self->{subject}->[$i] . "\n";
    }
  }
  return $str;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{alias} = [];
  $self->{note} = [];
  $self->{subject} = [];
  $self->{subjtype} = [];
  if ($params{string}) {
    $self->parse(string=>$params{string});
  }
  if ($params{name}) {
    $self->{formalname} = $params{name};
  }
  if ($params{informal}) {
      $self->{informalname} = $params{informal};
  }
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


