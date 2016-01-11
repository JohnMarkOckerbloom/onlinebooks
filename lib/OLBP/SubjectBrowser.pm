package OLBP::SubjectBrowser;
use OLBP::OLBPBrowser;
@OLBP::SubjectBrowser::ISA = qw(OLBP::OLBPBrowser);
use strict qw(vars subs);  # Can't use strict refs with our filehandles

sub _filehandle {
  my ($self, %params) = @_;
  return "SOOFH";
}

sub _get_subject_entry {
  my ($self, $idx) = @_;
  my $fh = $self->_filehandle();
  if ($self->{cachedkey}->{$idx}) {
    return ($self->{cachedkey}->{$idx}, $self->{cachedline}->{$idx});
  }
  my ($key, $entryidx) = $self->{indexer}->get_slot(index=>$idx);
  if (!$key) {
    return undef;
  }
  seek $fh, $entryidx, 0;
  my $line = <$fh>;
  $self->{last} = $idx;
  $self->{cachedkey}->{$idx} = $key;
  $self->{cachedline}->{$idx} = $line;
  return ($key, $line);
}

sub get_item_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $line) = $self->_get_subject_entry($idx);
  if ($key) {
    $line =~ s/\S*\s//;
    chop $line;
    return $line;
  }
  return undef;
}

sub _termlink {
  my ($term, $coll) = @_;
  return "<a href=\"$OLBP::scripturl/browse?type=lcsubc&amp;key="
          . OLBP::url_encode($term)
          . ($coll eq "x" ? "&amp;c=x" : "")
         . "\">$term</a>";
}

sub get_item_display {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $line) = $self->_get_subject_entry($idx);
  my $str = "";
  if ($line =~ /^(\S+) (.*)/) {
    my ($info, $name) = ($1, $2);
    my ($count, $plus);
    if ($info =~ /C(\d*)(\+?)/) {
      ($count, $plus) = ($1, $2);
    }
    if ($info =~ /A([\d,]+)/) {
      my @aliasidxs = split /,/, $1;
      my @linklist = ();
      $str = "<i>$name</i>: see ";
      foreach my $idx (@aliasidxs) {
        my $seename = $self->get_item_name(index=>$idx);
        push @linklist, _termlink($seename, $self->{collection});
      }
      $str .= join " or ", @linklist;
    } else {
      $str = _termlink($name, $self->{collection});
    }
    if ($count || $plus) {
      $str .= " (";
      if ($count) {
        $str .= "$count title" . (($count == 1) ? "" : "s");
      }
      if ($plus) {
         $str .= ($count ? ", plus " : "") . "subtopics";
      }
      $str .= ")";
    }
    return $str;
  } else {
    return undef;
  }
}

sub range_note {
  my ($self, %params) = @_;
  my $url = $OLBP::scripturl . '/browse?type=subject';
  if ($params{startname}) {
    my $key = $params{startname};
    $url .= "&amp;key=" . OLBP::url_encode($key);
  }
  my $msg = "Include extended shelves";
  if ($self->{collection} eq "x") {
    $msg = "Exclude extended shelves";
  } else {
    $url .= "&amp;c=x";
  }
  return " (<a href=\"$url\">$msg</a>)";
}

sub supply_sort_key { return OLBP::BookRecord::sort_key_for_subject($_[1]);}

sub nomatch_message {
  my ($self, $givenkey) = @_;
  my $msg = "No exact match for ";
  $givenkey =~ s/[\x00-\x1f]/ /g;
  $msg .= OLBP::html_encode($givenkey) . ". Showing nearby subjects.";
  return $msg;
}

sub items_name { return "Subjects";}

sub browse_type { return "subject";}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection}  = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/";
  }
  local *FH;
  my $fh = $self->_filehandle();
  my $fname = OLBP::subjectentriesfile($dir);
  open $fh, "< $fname" or return undef;
  $self->{fh} = $fh;
  my $iname = OLBP::indexfilename("subjects", $dir);
  $self->{indexer} = new OLBP::Index(name=>"subjects", filename=>$iname,
                                     cache=>1);
  # optimizing entry reading
  $self->{last} = -1;  
  return $self->SUPER::_initialize(%params);
}

1;


