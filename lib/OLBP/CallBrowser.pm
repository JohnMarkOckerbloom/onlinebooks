package OLBP::CallBrowser;
use OLBP::OLBPBrowser;
use OLBP::CallNumbers;
@OLBP::CallBrowser::ISA = qw(OLBP::OLBPBrowser);

my $tabletop = qq!style="vertical-align:top"!;

# First, some overview display function

sub _call_link {
  my ($collection, $key, $display) = @_;
  $key =~ s/\-.*//;
  my $url = $OLBP::scripturl . '/browse?type=lccn&amp;key=' . $key;
  if ($collection eq "x") {
    $url .= "&amp;c=x";
  }
  return "<a href=\"$url\">$display</a>";
}

sub _print_overview_row { 
  my ($coll, $cn, $pos, $left, $right, $overview) = @_;
  my $range = $cn->get_range(index=>$pos);
  my $description = $cn->get_title(index=>$pos);
  print "<li> ";
  my $text = "$range: $description";
  if (($left && $cn->inrange($left, $pos)) ||
      ($right && $cn->inrange($right, $pos))) {
    $text = "<b>$text</b>";
  }
  print _call_link($coll, $range, $text);
  if ($overview) {
    my $url = $OLBP::ncalloverview . "?key=" . OLBP::url_encode($range);
    if ($coll eq "x") {
      $url .= "&amp;c=x";
    }
    print " <i>(<a href=\"$url\">Overview</a>)</i>";
  }
  print "</li>";
}

sub display_overview {
  my ($self, %params) = @_;
  my $width = 1;
  my $cn = $self->{callnumbers};
  my ($left, $right);
  my $key = $params{key};
  if ($key) {
    if ($key =~ /(.*)-(.*)/) {
      $left = OLBP::BookRecord::sort_key_for_lccn($1);
      $right = OLBP::BookRecord::sort_key_for_lccn($2);
    } else {
      $left = OLBP::BookRecord::sort_key_for_lccn($key);
      $right = $left;
    }
  }
  print "<p style=\"text-align:center\"><b>Overview of " . $self->items_name() . "</b></p>";
  if ($left) {
    print "<p style=\"text-align:center\">(You were browsing at \"";
    print _call_link($self->{collection},
                     $left, key_to_html_display($left)) . "\"";
    if ($right && ($right ne $left)) {
      print " to " . _call_link($self->{collection},
                                $right, key_to_html_display($right)) . "\"";
    }
    print ")</p>";
  }
  my $jumpform = $self->jump_form();
  print "<table style=\"margin-left: auto; margin-right: auto\">";
  print "<tr><td>$jumpform</td></tr></table>";
  print "<table><tr>";
  if ($left) {
    $width = 2;
  }
  my $cursor = $cn->new_cursor();
  print "<td $tabletop width=\"" . 100 / $width . "%\">";
  print "<ul>";
  foreach my $letter ('A' .. 'Z') {
    my $pos = $cn->next_callrange(cursor=>$cursor, sortedlccn=>$letter);
    if (defined($pos)) {
       _print_overview_row($self->{collection}, $cn, $pos, $left, $right, ($width != 1));
    }
  }
  print "</ul></td>";
  if ($width == 2) {
    print "<td $tabletop width=\"" . 100 / $width . "%\"><ul>";
    my $leftl = substr($left, 0, 1);
    my $rightl = $leftl;
    if ($right) { 
      $rightl = substr($right, 0, 1);
    }
    $cursor = $cn->new_cursor();
    my $pos = $cn->next_callrange(cursor=>$cursor, sortedlccn=>$leftl);
    if (defined($pos)) {
      while (substr($cn->get_range(index=>$pos), 0, 1) le $rightl) {
        # eschew infinite loops at end of list
        last if !($cn->get_range(index=>$pos));
        _print_overview_row($self->{collection}, $cn, $pos, $left, $right);
        $pos++;
      }
    }
    print "</ul></td>";
  }
  print "</tr></table>\n";
  print "\n<!-- By the way, my collection is " . $self->{collection} . "-->\n";
  return $str;
}


# Now some specializations of the upper-level methods

sub get_item_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $br) = $self->get_key_and_bookrecord($idx);
  if ($br) {
    return $br->get_lccn();
  }
  return undef;
}

sub get_item_display {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $br) = $self->get_key_and_bookrecord($idx);
  if ($br) {
    return $br->short_entry();
  }
  return undef;
}

sub supply_sort_key { return OLBP::BookRecord::sort_key_for_lccn($_[1]);}

sub items_name { return "Library of Congress Call Numbers";}

sub range_note {
  my ($self, %params) = @_;
  my $url = $OLBP::ncalloverview;
  if ($params{startname}) {
    $url .= "?key=" . OLBP::url_encode($params{startname});
  }
  if ($params{endname}) {
    $url .= "-" . OLBP::url_encode($params{endname});
  }
  if ($self->{collection} eq "x") {
    $url .= "&amp;c=x";
  }
  my $parenthesized = "<a href=\"$url\">Overview</a>";
  my $ourl .= "?type=lccn&amp;key=" . OLBP::url_encode($params{startname});
  my $msg = "Include extended shelves";
  if ($self->{collection} eq "x") {
    $msg = "Exclude extended shelves";
  } else {
    $ourl .= "&amp;c=x";
  }
  $parenthesized .=  "; <a href=\"$ourl\">$msg</a>";
  return " ($parenthesized)";
}

sub browse_type { return "lccn";}

sub _makerow {
  my ($first, $second) = @_;
  return "<tr $tabletop><td>$first\&nbsp;</td><td>$second</td></tr>";
}

# We're assuming this is the cue for a new cursor
# and that we're only running one cursor at a time
# if this changes, we may have to get cursors more often

sub start_list {
  my ($self, %params) = @_;
  my $str = "<table>\n";
  $str .= _makerow("<b>Call number</b>", "<b>Item</b>");
  $self->{cursor} = $self->{callnumbers}->new_cursor();
  return $str;
}

sub end_list {return "</table>\n";}

sub early_end_marker {return "</table><p><b>End of list.</b></p><table>\n";}

sub item_in_list {
  my ($self, %params) = @_;
  my ($key, $br) = $self->get_key_and_bookrecord($params{index});
  my $lccn;
  my $str;
  my $cnstruct = $self->{callnumbers};
  if ($br) {
    $lccn = $br->get_lccn();
  }
  my $lccnsort = OLBP::BookRecord::sort_key_for_lccn($lccn);
  my $index = $cnstruct->next_callrange(sortedlccn=>$lccnsort,
                                        cursor=>$self->{cursor});
  while (defined($index)) {
    my $range = $cnstruct->get_range(index=>$index);
    my $title = $cnstruct->get_title(index=>$index);
    my $shortrange = $range;
    $shortrange =~ s/\-.*//;
    my $querypat = $OLBP::scripturl . "/browse?type=lccn&amp;key=$shortrange";
    if ($self->{collection} eq "x") {
      $querypat .= "&amp;c=x";
    }
    my $addons = "(<a href=\"$querypat\">Go to start of category</a>)";
    my @notes = $cnstruct->get_notes(index=>$index);
    foreach my $note (@notes) {
      $addons .= "<br>&nbsp;&nbsp;($note)";
    }
    $str .= _makerow("<b>$range</b>", "<b>$title</b> $addons");
    $index = $cnstruct->next_callrange(sortedlccn=>$lccnsort,
                                       cursor=>$self->{cursor}),
  }
  
  $lccn =~ s/ /&nbsp;/g;
  $str .= _makerow("$lccn", $params{string});
  return $str;
}

my $lctop = ['A' .. 'H', 'J' .. 'N', 'P' ..'V', 'Z'];

sub quick_picks {
  my ($self, %params) = @_;
  my $querypat = $OLBP::scripturl . "/browse?type=lccn&amp;key=%s";
  if ($self->{collection}) {
    $querypat .= "&amp;c=" . $self->{collection};
  }
  return $self->choice_list(pattern=>$querypat, list=>$lctop);
}

sub key_to_html_display {
  my $key = shift;
  $key =~ s/[\x00-\x1f]/ /g;
  $key =~ s/([A-Z]) ?0+/$1/g;
  return OLBP::html_encode($key);
}

sub nomatch_message {
  my ($self, $givenkey) = @_;
  my $msg = "No exact match for ";
  $givenkey =~ s/[\x00-\x1f]/ /g;
  $givenkey =~ s/([A-Z])0+/$1/g;
  $msg .= key_to_html_display($givenkey) . ". Showing nearby items.";
  return $msg;
}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection} = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/";
  }
  local *FH;
  my $iname = OLBP::indexfilename("lccn", $dir);
  # my $name = "records";
  # my $fname = OLBP::hashfilename($name);
  # my $hash = new OLBP::Hash(name=>$name, filename=>$fname);
  # $self->{entryhash} = $hash;
  $self->{store} = new OLBP::RecordStore(dir=>$OLBP::dbdir);

  $self->{indexer} = new OLBP::Index(name=>"lccn", filename=>$iname, cache=>1);
  $self->{callnumbers} = new OLBP::CallNumbers(filename=>$OLBP::callrangefile);
  return $self->SUPER::_initialize(%params);
}

1;


