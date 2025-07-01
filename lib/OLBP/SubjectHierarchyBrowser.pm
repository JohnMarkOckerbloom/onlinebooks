package OLBP::SubjectHierarchyBrowser;
use OLBP::SubjectNode;
use OLBP::RecordStore;

my @hashes = ("booksubnotes", "records", "subjectbooks");

my $RANOUT_TOKEN = "#--RANOUT--#";

my $MISC = "MISC";

# Some virtual functions that should be overridden in subtypes

sub find_right_slot {
  my ($self, %params) = @_;
  return ($params{index}, "");
}

sub get_index_size {return 0;}

sub items_name {return "Subject";}

sub range_note {return "";}

sub get_item_name {return "";}

sub quick_picks {return "";}

sub _jump_form {
  my ($self, $term) = @_;
  my $str = "<form style=\"text-align:center; padding-bottom:1em\" method=\"GET\" action=\"$OLBP::scripturl/browse\">\n";
  $str .= "Browsing subject area";
  $str .= ": <b>" . OLBP::html_encode($term) . "</b>";
  my ($coll, $msg) = ("x", "Include extended shelves");
  if ($self->{collection} eq "x") {
    ($coll, $msg) = ("c", "Exclude extended shelves");
  }
  $str .= " (" . $self->_livelink($msg, $term, $coll) . ")";
  # my $coll = $self->{collection} || "c";
  $str .= "<br>You can also ";
  $str .= "  <a href=\""
     .  $OLBP::scripturl . "/browse?type=subject&amp;key=". OLBP::url_encode($term)
     . "&amp;c=" . $coll
     . "\">browse an alphabetical list</a>";
  $str .= " from this subject ";
  $str .= "or from: ";
  $str .= "<input type=\"hidden\" name=\"type\" value=\"subject\">\n";
  $str .= "<input type=\"hidden\" name=\"c\" value=\"$coll\">\n";
  $str .= "<input name=\"key\" size=10 value=\"\"></form>\n";
  return $str;
}

sub start_list {return "";}
sub end_list {return "";}
sub early_end_marker {return "";}

sub item_in_list {
  my ($self, %params) = @_;
  return $params{string};
}

# End of virtual functions

# Some helper functions currently implemented here since they're
# fairly generic.  Some of these may move down into subclasses later
# on if they turn out to be not so generic
# (though navigation_line must be implemented somewhere, under this
# class's display_browse implementation)

sub navigation_line {
  my ($self, %params) = @_;
  my $slot = $params{slot};
  my $backslot = $params{backslot};
  my $nextslot = $params{nextslot};
  my $isize = $params{isize};
  my $previcon = "&lt;previous";
  my $prevurl;
  my $str;

  if ($slot) {
    $prevurl = $self->get_query_url(index=>$backslot);
  }
  if ($prevurl) {
    $str = "<a href=\"$prevurl\">$previcon</a>";
  } else {
    $str = $previcon;
  }
  my $picks = $self->quick_picks();
  if ($picks) {
    $str .= " -- $picks -- ";
  } 
  my $nexticon = "next&gt;";
  my $nexturl;
  if ($nextslot < $isize) {
    $nexturl = $self->get_query_url(index=>$nextslot);
  }
  if ($nexturl) {
    $str .= "<a href=\"$nexturl\">$nexticon</a>";
  } else {
    $str .= $nexticon;
  }
  return $str;
}

# Displays the choices

sub choice_list {
  my ($self, %params) = @_;
  my $pattern = $params{pattern};
  if (!($params{list})) {
    return "";
  } 
  my @list = @{$params{list}};
  my $separator = " ";
  if (defined($params{separator})) {
    $separator = $params{separator};
  }
  my @linklist;
  foreach my $value (@list) {
    my $link = "<a href=\"" . sprintf($pattern, $value) . "\">$value</a>";
    push @linklist, $link;
  }
  return join $separator, @linklist;
}

sub _lookup_key {
  my ($self, $key) = @_;
  my $hashname = "booksubnotes";
  if ($self->{collection} eq "x") {
    $hashname = OLBP::termhash($hashname, $key);
  }
  return $self->{$hashname}->get_value(key=>$key);
}

sub _find_right_node {
  my ($self, $term) = @_;
  my $key = OLBP::BookRecord::search_key_for_subject($term);
  my $str = $self->_lookup_key($key);
  if (!defined($str)) {
    return 0;
  }
  my $node = new OLBP::SubjectNode(name => $term);
  $node->expand(infostring=>$str);
  return $node;
}

sub _livelink {
  my ($self, $item, $link, $coll, $cmd) = @_;
  if (!$link) {
    $link = $item;
  }
  my $url = _get_query_url($link, $cmd);
  if (!$coll) {
    $coll = $self->{collection};
  }
  if ($url) {
    if ($coll eq "x") {
      $url .= "&amp;c=x";
    }
    return "<a href=\"$url\">" . $item . "</a>";
    # return "<a href=\"$url\">" . OLBP::html_encode($item) . "</a>";
  }
  return OLBP::html_encode($item);
}

sub _print_related_list { 
  my ($self, $header, @list) = @_;
  my $size = scalar(@list);
  if ($size) {
    print "<b>$header" . (($size == 1) ? "" : "s");
    print ":</b><ul>";
    foreach my $item (@list) {
      print "<li>" . $self->_livelink($item) . "</li>";
    }
    print "</ul>";
  }
}

sub _get_query_url {
  my ($term, $cmd) = @_;
  if ($term) {
    $cmd ||= "/browse?type=lcsubc";
    return $OLBP::scripturl . "$cmd&amp;key=" . OLBP::url_encode($term);
  }
  return "";
}

sub get_books_with_subject {
  my ($self, %params) = @_;
  my $key = $params{key};
  if (!$key) {
    my $term = $params{term};
    $key = OLBP::BookRecord::search_key_for_subject($term);
  }
  return () if (!$key);
  if (!$self->{subcache}->{$key}) {
    my $val = $self->{subjectbooks}->get_value(key=>$key);
    my @booklist;
    if ($val) {
      my @refarray = split /\s+/, $val;
      foreach my $bookid (@refarray) {
        next if (!$bookid);
        # my $str = $self->{records}->get_value(key=>$bookid);
        # my $br = new OLBP::BookRecord(string=>$str);
        my $br = $self->{store}->get_record(id=>$bookid);
        if ($br) {
          push @booklist, $br;
        }
      }
    }
    print "\n<!-- calling substitute with " . scalar(@booklist) . " works -->\n";
    @booklist = OLBP::BookRecord::substitute_works(@booklist);
    print "\n<!-- substitute returned with " . scalar(@booklist) . " works -->\n";
    $self->{subcache}->{$key} = \@booklist;
  }
  return @{$self->{subcache}->{$key}};
}

sub show_books_with_subject {
  my ($self, %params) = @_;
  my $term = $params{term};
  my $header = $params{header};
  my $key = OLBP::BookRecord::search_key_for_subject($term);
  if ($params{seen}->{$key}) {
     print "\n<!-- we think we've seen $key -->\n";
     return 0;
  } else {
    $params{seen}->{$key} = 1;
  }
  my @records = $self->get_books_with_subject(key=>$key);
  my $count = scalar(@records);
  if ($count) {
    print "<b>$header: " . $self->_livelink($term) . "</b>";
    print "<ul class=\"nodot\">";
    foreach my $br (@records) {
      print "<li>" . $br->short_entry() . "</li>";
    }
    print "</ul>";
  }
  return $count;
}

sub _recur_under_subject {
  my ($self, %params) = @_;
  my $max = $params{max};
  my $term = $params{term};
  my $seen = $params{seen};
  my %breadth = ();
  my $breadthcount = 0;
  my $submax;

  if ($params{seen}->{$term}) {
     return $max;
  }
  my $count = $self->show_books_with_subject(term=>$term, seen=>$seen,
                                             header=>"Filed under");
  # Not sure if strictly necessary, but there if needed
  # (but we do this *after* we show books with subject, not before)
  $params{seen}->{$term} = 1;
  $max -= $count;
  if ($max <= 0) {
    $params{seen}->{$RANOUT_TOKEN} = 1;
    return $max;
  }
  my $node = $self->_find_right_node($term);
  if ($node) {
    # To avoid going off on long depth-first tangents, we first
    # scan for breadth, and try to limit going down past the next level
    # if it has more items in it than we can display
    my @subterms = $node->narrower_terms();
    if (scalar(@subterms)) {
      for (my $i = scalar(@subterms) - 1; $i >= 0; $i--) {
        next if (!$subterms[$i]);
        $breadth{$subterms[$i]} = $breadthcount;
        if ($breadthcount <= $max) {
          $breadthcount +=
              scalar($self->get_books_with_subject(term=>$subterms[$i]));
        }
      }
    }
    foreach my $subterm (@subterms) {
      next if (!$subterm || ($term eq $subterm));
      if ($max < 0) {
        $params{seen}->{$RANOUT_TOKEN} = 1;
        return $max;
      }
      if ($max < $breadth{$subterm}) {
        # we're all full up just at this level, so just show one level down
        $max += $self->_recur_under_subject(term=>$subterm,
                                            max=>0, seen=>$seen);
      } else {
        # show as far as we can go given the remaining 1-level terms to cover
        my $submax = $max - $breadth{$subterm};
        my $aftermax = $self->_recur_under_subject(term=>$subterm,
                                                   max=>$submax, seen=>$seen);
        $max += ($aftermax - $submax);
       
      }
    }
  }
  return $max;
}

# this sets up a hash to cover subjects already seen, then calls recursive fn
sub show_books_under_subject {
  my ($self, %params) = @_;
  my $node;                   
  $params{seen} = {};
  my $downonly = $params{downonly};
  my $max = $self->_recur_under_subject(%params);
  # Still some space left; go to the related and broader terms
  # (note that we only do this once)
  print "\n<!-- we ended with max $max -->\n";
  if ($params{seen}->{$RANOUT_TOKEN}) {
    print "<p><b>More items available under narrower terms.</b></p>";
    return $max;
  }
  if ($max > 0 && !$downonly) {
    $node = $self->_find_right_node($params{term});
    if ($node) {
      print "<p><b>Items below (if any) are from related and broader terms.</b></p>";
      foreach my $term ($node->related_terms()) {
        $max = $self->_recur_under_subject(term=>$term,
                                           max=>$max, seen=>$params{seen});
        last if ($max <= 0);
      }
    }
  }
  if ($node && $max > 0) {
    foreach my $term ($node->broader_terms()) {
      $max = $self->_recur_under_subject(term=>$term,
                                         max=>$max, seen=>$params{seen});
      last if ($max <= 0);
    }
  }
  if ($params{seen}->{$RANOUT_TOKEN}) {
    print "<p><b>More items available under broader and related terms at left.</b></p>";
  }
  return $max;
}

# what happens when we call display_browse and there's nothing under the term
# here we fail back to the alphabetic browser

sub _notermhit {
  my ($self, %params) = @_;
  my $term = $params{key};
  my $chunksize = $params{chunksize};
  my $backup = new OLBP::SubjectBrowser();
  $backup->display_browse(key=>$term, chunksize=>$chunksize);
  return 1;
}

sub get_browser_info_url {
  return "$booksurl/subjectbrowsedoc.html";
}

# notes are pre-entified, don't need to escape them
sub _print_scope_notes {
  my ($self, $node) = @_;
  my @notes = $node->scope_notes();
  foreach my $note (@notes) {
    print "<p>";
    # we now have cross-refs in single brackets
    while ($note =~ /(.*?)\[(.*?)\](.*)/) {
    # while ($note =~ /(.*?)\[\[(.*?)\]\](.*)/) {
      print $1;
      my $term = $2;
      my $link = $term;
      $note = $3;
      $link =~ s/[,]$//;
      $link =~ s/\s*--\s*/ -- /g;
      my $key = OLBP::BookRecord::search_key_for_subject($link);
      if ($self->_lookup_key($key)) {
        print $self->_livelink($term, $link);
      } else {
        print $term;
      }
    }
    print $note;
    print "</p>";
  }
}

sub _print_author_link {
  my ($self, $node) = @_;
  if ($node->author_key()) {
     my $name = $node->get_name();
     my $msg = "Online books by this author";
     print "<p>";
     print $self->_livelink($msg, $name, 0, "/lookupname?");
     print " are available.</p>\n";
  }
}

sub _print_seealso_links {
  my ($self, $node) = @_;
  my $display = $node->get_name();
  return if (!$display);
  my $wikikey = OLBP::BookRecord::search_key_for_subject($display);
  my $wikiurl = $self->{wikihash}->get_value(key=>$wikikey);
  print "<p>";
  # print "<!-- from $self->{wikihash}->{filename}, -$wikikey- yields -$wikiurl- -->\n";
  print "See also what's at ";
  if ($wikiurl) {
    $wikiurl = $OLBP::wpstub . $wikiurl;
    print "<a href=\"$wikiurl\">Wikipedia</a>, ";
  }
  my $url = $OLBP::seealsourl . "?su=" . OLBP::url_encode($display);
  print "<a href=\"$url\">your library</a>, or ";
  print "<a href=\"$url\&amp;library=0CHOOSE0\">elsewhere</a>.";
  print "</p>\n";
}

sub _print_subject_aliases {
  my ($self, $node) = @_;
  my @aliases = $node->aliases();
  if (scalar(@aliases)) {
    print "<b>Used for:</b><ul>";
    foreach my $alias (@aliases) {
      # now that aliases are under entity control, we don't have to escape them
      # print "<li>" . OLBP::html_encode($alias) . "</li>\n";
      print "<li>$alias</li>\n";
    }
    print "</ul>";
  }
}

sub _print_subject_summary {
  my ($self, $term, $node, $seealso) = @_;
  my $display = $node->get_name();
  if (!$display) {
    $display = OLBP::html_encode($term);
  }
  print "<h2 style=\"margin: 0; padding:0; border:0\">$display</h2>";
  $self->_print_scope_notes($node);
  $self->_print_author_link($node);
  # if ($seealso) {
    $self->_print_seealso_links($node);
  # }
  $self->_print_related_list("Broader term", $node->broader_terms());
  $self->_print_related_list("Related term", $node->related_terms());
  $self->_print_related_list("Narrower term", $node->narrower_terms());
  $self->_print_subject_aliases($node);
}

sub _print_subject_banner {
  my ($self, $term) = @_;
  # print "<p style=\"text-align:center\">";
  # print "Browsing subject area";
  # print ": <b>" . OLBP::html_encode($term) . "</b>";
  # my ($coll, $msg) = ("x", "Include extended shelves");
  # if ($self->{collection} eq "x") {
  #   ($coll, $msg) = ("c", "Exclude extended shelves");
  # }
  # print " (" . $self->_livelink($msg, $term, $coll) . ")";
  my $jumpform = $self->_jump_form($term);
  print "$jumpform";
  # print "</p>$jumpform";
  # print "<table style=\"margin-left: auto; margin-right: auto\">";
  # print "<tr><td>$jumpform</td></tr></table>";
}

# The public interface methods

sub display_browse {
  my ($self, %params) = @_;
  my $term = $params{key};
  my $chunksize = $params{chunksize};
  my $seealso = $params{seealso};

  my $node = $self->_find_right_node($term);
  if (!$node) {
    return $self->_notermhit(%params);
  }

  $self->_print_subject_banner($term, $node);
  print "<table style=\"margin-top=2.5em\"><tr>\n";
  print "<td style=\"width:40%; vertical-align:top\">";
  $self->_print_subject_summary($term, $node, $seealso);
  print "</td><td style=\"width:60%; vertical-align:top\">";
    $self->show_books_under_subject(term=>$term, max=>50);
  print "</td></tr></table>\n";
  return 1;
}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection} = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/"; 
  }
  foreach my $hashname (@hashes) {
    # my $fname = OLBP::hashfilename($hashname);
    my $fname = OLBP::hashfilename($hashname, $dir);
    my $hash = new OLBP::Hash(name=>$hashname, filename=>$fname);
    $self->{$hashname} = $hash;
    if ($self->{collection} eq "x") {
      foreach my $start ($MISC, ('a' .. 'z')) {
        my $hashname = "booksubnotes-$start";
        my $fname = OLBP::hashfilename($hashname, $dir);
        my $hash = new OLBP::Hash(name=>$hashname, filename=>$fname);
        $self->{$hashname} = $hash;
      }
    }
  }
  my $wikidir = $OLBP::dbdir . "wiki/"; 
  my $wikifile = $wikidir . "subtowp.hsh";
  $self->{wikihash} = new OLBP::Hash(name=>"subtowp", filename=>$wikifile);
  $self->{store} = new OLBP::RecordStore(dir=>$OLBP::dbdir);
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
