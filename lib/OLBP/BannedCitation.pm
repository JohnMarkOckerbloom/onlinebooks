package OLBP::BannedCitation;
use strict;
use JSON;

sub _readjsonfile {
  my ($self, $path) = @_;
  my $str;
  open my $fh, "< $path" or return undef;
  binmode $fh, ":utf8";
  while (<$fh>) {
    $str .= $_;
  }
  close $fh;
  return $self->{parser}->decode($str);
}

sub get_json {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  $fname =~ s/[^A-Za-z0-9\-]//g;     # sanitize input
  my $path = $self->{dir} . $fname . ".json";
  $self->{title} = $path;
  return $self->_readjsonfile($path);
}

sub _isdatesuffix {
  my $s = shift;
  return (($s =~ /^[-\d\s]*$/) || ($s =~ /^\s*\d*-\d*\s+B\.\s*C\.\s*$/));
}

sub _informalname {
  my $name = shift;
  if ($name =~ /^([^,]+),\s+(.+)/) {
    $name = $1;
    my $s2 = $2;
    if (_isdatesuffix($s2)) {
      $s2 = "";
    } elsif ($s2 =~ /([^,(\[]*)[,(\[]/) {
      $s2 = $1;
      $s2 =~ s/\s+$//;
    }
    if ($s2) {
      $name = $s2 . " " . $name;
    }
  }
  return $name;
}

# Right now we're only returning the authorized form of an author or editor
# but we'll get more robust as we need to

sub _display_person {
  my ($self, $person, $inverted) = @_;
  my $str = "";
  if ($inverted) {
    if ($person->{"inverted"}) {
      return OLBP::html_encode($person->{"inverted"});
    }
    my $invertedname = $person->{"authorized"};
    # remove extra stuff past first comma or paren following another comma
    if ($invertedname =~ /^([^,]*,[^,]*)\(/) {
      $invertedname = $1;
    } elsif ($invertedname =~ /^([^,]*,[^,]*),/) {
      $invertedname = $1;
    }
    return OLBP::html_encode($invertedname);
  }
  if ($person->{"name"}) {
    # This way, if the inverted authorized looks bad, we can override w name
    $str = OLBP::html_encode($person->{"name"});
  } elsif ($person->{"authorized"}) {
    $str = OLBP::html_encode(_informalname($person->{"authorized"}));
  }
  if ($person->{"using"}) {
    $str .= " (using the name " . OLBP::html_encode($person->{"using"}) . ")";
  }
  return $str;
}

# returns a quick author/editor/etc. credit for a summary line
# just doing a quick summary for now

sub get_author_summary {
  my ($self, %params) = @_;
  my $json = $self->{json};
  return "" if (!$json);
  if ($json->{"authors"}) {
    if (scalar(@{$json->{"authors"}} == 2)) {
       return $self->_display_person($json->{"authors"}->[0], 1) 
        .  " and " . $self->_display_person($json->{"authors"}->[1]);
    }
    return $self->_display_person($json->{"authors"}->[0], 1) . " et al";
  }
  if ($json->{"author"}) {
    return $self->_display_person($json->{"author"}, 1);
  }
  if ($json->{"editor"}) {
    return $self->_display_person($json->{"editor"}, 1) . " (ed.)";
  }
  return "";
}

sub get_title {
  my ($self, %params) = @_;
  my $json = $self->{json};
  return "" if (!$json);
  return $self->{json}->{title};
}

sub display_html {
  my ($self, %params) = @_;
  return "" if (!$self->{json});
  my $str = "";
  my $authorsum = $self->get_author_summary();
  if ($authorsum) {
    $str .= "$authorsum";
    $str .= "." if (!($authorsum =~ /\.$/));
    $str .= " ";
  }
  my $title = $self->{json}->{title};
  $str .= "<cite>$title</cite>";
  $str .= "." if (!($title =~ /\.$/));
  my $edition = $self->{json}->{edition};
  if ($edition) {
    $str .= " $edition.";
  }
  my $loc = $self->{json}->{"publisher-location"};
  if ($loc) {
    $str .= " $loc:";
  }
  my $name = $self->{json}->{"publisher-name"};
  if ($name) {
    $str .= " $name";
  }
  my $date = $self->{json}->{"date"};
  if ($date) {
    $str .= ", $date";
  }
  $str .= ".";
  return $str;
}

sub get_publication_date {
  my ($self, %params) = @_;
  my $json = $self->{json};
  return "" if (!$json);
  my $fp = $json->{"first-published"};
  return "" if (!$fp);
  return $fp->{"date"};
}

sub get_publication_year {
  my ($self, %params) = @_;
  my $date = $self->get_publication_date();
  if ($date =~ /^(\d\d\d\d)/) {
    return $1;
  }
  return 0;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{id} = $params{id};
  $self->{parser} = OLBP::BannedUtils::get_json_parser();
  if ($self->{id}) {
    $self->{json} = $self->get_json(filename=>$self->{id});
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

