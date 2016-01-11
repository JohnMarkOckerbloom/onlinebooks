package OLBP::AuthorBrowser;
use OLBP::OLBPBrowser;
@OLBP::AuthorBrowser::ISA = qw(OLBP::OLBPBrowser);
use strict qw(vars subs);  # Can't use strict refs with our filehandles

sub _filehandle {
  my ($self, %params) = @_;
  return "OOFH";
}

sub _get_author_entry {
  my ($self, $idx) = @_;
  my $fh = $self->_filehandle();
  if ($self->{cachedkey}->{$idx}) {
    return ($self->{cachedkey}->{$idx}, $self->{cachedline}->{$idx});
  }
  my ($key, $entryidx) = $self->{indexer}->get_slot(index=>$idx);
  if (!$key) {
    return undef;
  }
#  if (($self->{last}) ne $idx + 1 ||
#       $self->{last} == $self->{indexer}->get_size()) {
    seek $fh, $entryidx, 0;
#  }
  my $line = <$fh>;
  $self->{last} = $idx;
  $self->{cachedkey}->{$idx} = $key;
  $self->{cachedline}->{$idx} = $line;
  return ($key, $line);
}

sub get_item_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $line) = $self->_get_author_entry($idx);
  if ($key) {
    $line =~ s/\S*\s//;
    chop $line;
    return $line;
  }
  return undef;
}

sub get_item_display {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $line) = $self->_get_author_entry($idx);
  if ($line =~ /^(\S+) (.*)/) {
    my ($info, $name) = ($1, $2);
    my $count;
    if ($info =~ /C(\d+)/) {
      $count = $1;
    }
    my $goodname = $name;
    if ($info =~ /A(\d+)/) {
      my $alias = $1;
      $name = "<i>$name</i>";
      $goodname = $self->get_item_name(index=>$alias);
      $name .= ", aka " . $goodname;
    }
    my $lookupurl = "$OLBP::scripturl/lookupname?key="
                   . OLBP::url_encode($goodname);
    if ($self->{collection} eq "x") {
      $lookupurl .= "&amp;c=x";
    }
    $name = "<a href=\"$lookupurl\">$name</a>";
    return "$name ($count title" . (($count == 1) ? "" : "s") . ")";
  } else {
    return undef;
  }
}

sub range_note {
  my ($self, %params) = @_;
  my $url = $OLBP::scripturl . '/browse?type=atitle';
  if ($params{startname}) {
    my $key = $params{startname};
    $url .= "&amp;key=" . OLBP::url_encode($key);
  }
  if ($self->{collection} eq "x") {
    $url .= "&amp;c=x";
  }
  my $parenthesized = "<a href=\"$url\">Show titles</a>";
  my $ourl = $OLBP::scripturl . '/browse?type=author';
  if ($params{startname}) {
    my $key = $params{startname};
    $ourl .= "&amp;key=" . OLBP::url_encode($key);
  }
  my $msg = "Include extended shelves";
  if ($self->{collection} eq "x") {
    $msg = "Exclude extended shelves";
  } else {
    $ourl .= "&amp;c=x";
  }
  $parenthesized .=  "; <a href=\"$ourl\">$msg</a>";
  return " ($parenthesized)";
}


sub supply_sort_key { return OLBP::BookRecord::sort_key_for_name($_[1]);}

sub nomatch_message {
  my ($self, $givenkey) = @_;
  my $msg = "No exact match for ";
  $givenkey =~ s/\x02/,/g;
  $givenkey =~ s/[\x00-\x1f]/ /g;
  $msg .= OLBP::html_encode($givenkey) . ". Showing nearby names.";
  return $msg;
}

sub items_name { return "Authors";}

sub browse_type { return "author";}

# special function to return canonical index if any

sub get_canonical_index {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $line) = $self->_get_author_entry($idx);
  if ($line =~ /^(\S+) (.*)/) {
    my ($info, $name) = ($1, $2);
    if ($info =~ /A(\d+)/) {
      return $1;
    }
  } 
  return $idx;
}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection} = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/";
  }
  local *FH;
  my $fh = $self->_filehandle();
  my $fname = OLBP::authorentriesfile($dir);
  my $iname = OLBP::indexfilename("authors", $dir),
  open $fh, "< $fname" or return undef;
  $self->{fh} = $fh;
  $self->{indexer} = new OLBP::Index(name=>"authors",
                                     filename=>$iname, cache=>1);
  # optimizing entry reading
  $self->{last} = -1;  
  return $self->SUPER::_initialize(%params);
}

1;


