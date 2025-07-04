package OLBP::CopyrightInfo;
use strict;
use JSON;

my $cgiprefix = "https://onlinebooks.library.upenn.edu/webbin/";
my $serialprefix = $cgiprefix . "serial?id=";
my $cinfoprefix  = $cgiprefix . "cinfo/";
my $inforeqprefix = $cgiprefix . "olbpcontact?type=backfile";
my $codburl = "https://publicrecords.copyright.gov/";
my $cceurl  = "https://onlinebooks.library.upenn.edu/cce/";
my $firstperiodurl  = $cceurl . "firstperiod.html";
my $backfileurl = $cgiprefix . "backfile";

my @month = ("January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December");

my $PDUS         = "NoC-US";
my $COPYRIGHTED  = "InC";

$OLBP::CopyrightInfo::ALL_COPYRIGHTED = "All";
$OLBP::CopyrightInfo::ALL_PD          = "N/A";
$OLBP::CopyrightInfo::NO_RENEWAL      = "None";
$OLBP::CopyrightInfo::UNCLEAR_RENEWAL = "See record";

my $disclaimer = qq!The preparers of this page do not represent
 the publishers or the rightsholders of this publication.  To the best
 of their knowledge, the information in it is correct, and complete within
 any limits specified above.  It may still have inadvertent errors and omissions,
 however; if you know of any, please contact the page maintainer shown above.
 This page is not legal advice.!;
  

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

sub _errorpage {
  my ($msg) = @_;
  print "<title>Error</title></head>";
  print $OLBP::bodystart;
  print "<p>Sorry, an error occurred.";
  if ($msg) {
    print " ($msg)";
  }
  print "</p>";
  print $OLBP::bodyend;
  exit 0;
}

sub _tabrow {
  my ($self, %params) = @_;
  my $attr = $params{attr};
  my $value = $params{value};
  my $tabletop = qq!style="vertical-align:top"!;
  my $str = "<tr><td $tabletop><b>";
  $str .= $attr;
  $str .= ":</b></td><td $tabletop>";
  $str .= "$value</td></tr>\n";
  return $str;
}

sub _encode_list {
  my ($listref, $separator) = @_;
  $separator ||= ", ";
  my @newlist;
  foreach my $name (@{$listref}) {
    push @newlist, OLBP::html_encode($name);
  }
  return join ($separator, @newlist);
}

# returns the ID of a predecessor or successor 
# (based on the property) that reports online content.
# Returns undef if none found, no directory, or multiple preds/successors found
# Also bails if more than 6 steps (cheap way to avoid infinite loops)

sub _online_down_the_chain {
  my ($self, $json, $property) = @_;
  my $iterations = 0;
  return undef if (!$self->{dir} || !$json || !$property);
  while ($iterations < 6) {
    my @idlist = _idlist($json->{$property});
    return undef if (!(scalar(@idlist) == 1));
    my $id = $idlist[0];
    my $path = $self->{dir} . "$id.json";
    $json = $self->_readjsonfile($path);
    return undef if (!$json);
    return $id if ($json->{"online"} eq "1"); # ignore if URL
    $iterations += 1;
  }
  return undef;
}

# Returns the ID of a predecessor (immedaite or down a chain)
# of the supplied JSON file, if it reports online content
sub online_predecessor {
  my ($self, %params) = @_;
  my $json = $params{json};
  return $self->_online_down_the_chain($json, "preceded-by");
}

sub online_successor {
  my ($self, %params) = @_;
  my $json = $params{json};
  return $self->_online_down_the_chain($json, "succeeded-by");
}

sub _format_with_title {
  my ($self, $id, $note) = @_;
  return $note if (!$self->{dir});
  my $path = $self->{dir} . $id . ".json";
  my $json = $self->_readjsonfile($path);
  my $isonline = $json->{"online"};
  my $title = $json->{"title"};
  return $note if (!$title);
  if ($note =~ /($title)(.*)/) {
    $note = "<cite>$1</cite>$2";
  }
  if ($isonline) {
    $note = "<strong>$note</strong>";
  }
  return $note;
}

sub _link_list {
  my ($self, $listref, $default) = @_;
  my @links = ();
  foreach my $item (@{$listref}) {
    my $note = $item->{"note"};
    my $url = $item->{"url"};
    my $id = $item->{"id"};
    if ($id && $note) {
      $note = $self->_format_with_title($id, $note);
    }
    $note ||= OLBP::html_encode($default);
    if ($url) {
      $note ||= OLBP::html_encode($url);
      push @links, qq!<a href="$url">$note</a>!;
    } elsif ($id) {
      $url = $cinfoprefix . $id;
      $note ||= OLBP::html_encode($id);
      push @links, qq!<a href="$url">$note</a>!;
    }
  }
  return @links;
}

sub _date_string {
  my ($date, $brief) = @_;
  if ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
    return $month[$2-1] . " " . int($3) . ", $1";
  }
  if ($date =~ /^(\d\d\d\d)-(\d\d)$/) {
    return $month[$2-1] . " $1";
  }
  if ($date =~ /^(\d\d\d\d)-(.*)$/) {
    return "$2 $1";
  }
  return $date;
}

sub _number_string {
  my ($number) = @_;
  if (int($number) eq $number) {
    return "no. " . OLBP::html_encode($number);
  }
  # not a number, but an issue title.  Return literally.
  return OLBP::html_encode($number);
}

sub _display_no {
  my (%params) = @_;
  my $completeness = $params{completeness};
  my $context = $params{context};
  my $what = $params{what} || "issue";
  my $active = (($params{completeness} =~ /^active\//) ? " active" : "");
  my $source = $params{source};
  my $str = "";
  if ($context eq "serialpage") {
    $str = "No$active $what ";
    if ($what eq "issue" &&
        $params{firstcont} && $params{firstcont} eq "none") {
      $str .= "or contribution ";
    }
    $str .= "copyright renewals were found";
  } else {
    $str = "no$active $what renewals found";
  }
  if ($context eq "serialpage") {
    $str .= " for this serial";
    return $str;
  }
  if ($source eq "cce") {
    $str .= " in CCE";
  } elsif (($source eq "cce+database") || ($source eq "cce+cprs")) {
    $str .= " in CCE or CPRS";
  } elsif (($source eq "database") || ($source eq "cprs")) {
    $str .= " in CPRS";
  }
  return $str;
}

sub _display_issue {
  my (%params) = @_;
  my $issue = $params{issue};
  my $str = "";
  return "" if (!$issue);
  my $date = $issue->{"issue-date"};
  if ($date) {
    $str = OLBP::html_encode(_date_string($date));
    if ($params{bolddate}) {
      $str = "<b>$str</b>";
    }
  }
  my $hasdate = $str;
  if ($issue->{"volume"} || $issue->{"number"} || $issue->{"series"}) {
    if ($hasdate) {
      $str .= " (";
    }
    if ($issue->{"series"}) {
      if ($issue->{"series"} eq int($issue->{"series"})) { 
        $str .= "series " . OLBP::html_encode($issue->{"series"});
      } else {
        $str .= OLBP::html_encode($issue->{"series"}) ." series";
      }
      $str .= ", " if ($issue->{"volume"} || $issue->{"number"});
    }
    if ($issue->{"volume"}) {
      $str .= "v. " . OLBP::html_encode($issue->{"volume"});
      $str .= " " if ($issue->{"number"});
    }
    if ($issue->{"number"}) {
      $str .= _number_string($issue->{"number"});
    }
    if ($hasdate) {
      $str .= ")";
    }
  }
  if ($issue->{"cdate"}) {
    $str .= ", " if ($hasdate || $issue->{"volume"} || $issue->{"number"});
    $str .= "&copy; " . OLBP::html_encode(_date_string($issue->{"cdate"}));
  }
  if ($issue->{"note"}) {
    $str .= "; " if ($str);
    $str .= OLBP::html_encode($issue->{"note"});
  }
  return $str;
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

sub _display_person {
  my ($self, $person) = @_;
  my $str = "";
  if ($person->{"name"}) {
    # This way, if the inverted authorized looks bad, we can override w name
    $str = OLBP::html_encode($person->{"name"});
  } elsif ($person->{"authorized"}) {
    $str = OLBP::html_encode(_informalname($person->{"authorized"}));
  }
  if ($person->{"using"}) {
    $str .= " (using the name " . OLBP::html_encode($person->{"using"}) . ")";
  }
  my $contact = $person->{"contact"};
  if ($contact =~ /http/) {
    # web address
    $str = qq!<a href="$contact">$str</a>!;
  } elsif ($contact =~ /(.+)\@(.+)/) {
    my ($username, $domain) = ($1, $2);
    $domain =~ s/\./ (dot) /g;
    $str .= " (" . OLBP::html_encode($username) . " <b>(at)</b> " .
                   OLBP::html_encode($domain) . ")";
  }
  if ($self->{arfile}) {
    my $rightsid = $person->{"lcna"};
    if ($rightsid) {
      my $url = $self->{arfile}->rights_url(id=>$rightsid);
      if ($url) {
         $str .= qq! [<a href="$url">Permissions</a>]!;
      }
    }
  }
  return $str;
}

sub _get_first_renewed_issue {
  my ($json) = @_;
  if ($json->{"first-renewed-issue"}) {
    return $json->{"first-renewed-issue"};
  }
  if ($json->{"renewed-issue-completeness"} =~ /^active\//) {
    if ($json->{"renewed-issues"}) {
      return $json->{"renewed-issues"}->[0];
    }
  }
  return undef;
}

sub _get_first_renewed_contribution {
  my ($json) = @_;
  if ($json->{"first-renewed-contribution"}) {
    return $json->{"first-renewed-contribution"};
  }
  if ($json->{"renewed-contribution-completeness"} =~ /^active\//) {
    if ($json->{"renewed-contributions"}) {
      return $json->{"renewed-contributions"}->[0];
    }
  }
  return undef;
}

sub _get_source_note {
  my ($json, $sourcename, $sourcefor, $nolink) = @_;
  my $source = $json->{$sourcename};
  if (!$source) {
    my $what = $json->{$sourcefor};
    return "" if (!$what);
    if ($what->{"issue-date"}) {
      $what = $what->{"issue-date"};
    } elsif ($what->{"issue"} && $what->{"issue"}->{"issue-date"}) {
      $what = $what->{"issue"}->{"issue-date"};
    }
    if ($what && $what gt "1950" && $what lt "1964") {
      $source = "cprs";
    }
  }
  return "" if (!$source);
  if (($source eq "database") || ($source eq "cprs")) {
    if ($nolink) {
      return qq!; see CPRS!;
    }
    return qq!; see <a href="$codburl">CPRS</a>!;
  }
  if ($source =~ /(\d\d\d\d)(.*)/) {
    my ($year, $rest) = ($1, $2);
    if ($rest =~ /jan.*jun/i) {
      $rest = "January-June";
    } elsif ($rest =~ /jul.*dec/i) {
      $rest = "July-December";
    }
    if ($year >= 1950 && $year <= 1978 && !$nolink) {
      my $catpageurl = $cceurl . $year . "r.html";
      my $str = qq!; see <a href="$catpageurl">$year</a>!;
      if ($rest) {
         $str .= " " . OLBP::html_encode($rest);
      }
      return $str;
    }
    if ($rest) {
      return "; see " . OLBP::html_encode("$year $rest");
    } else {
      return "; see " . OLBP::html_encode("$year");
    }
  }
  if ($source) {
    return qq"; see " . OLBP::html_encode($source);
  }
  return "";
}

sub _print_completeness_note {
  my ($note, $type) = @_;
  my $str = "";
  if ($note =~ /^active\/auto(matic|renewals)$/) {
    $str = "This includes all active $type renewals prior to " .
           " 1964, when automatic renewals began.  It might not show all" .
           " renewals from 1964 onward."
  } elsif ($note eq "active/end") {
    $str = "This includes all active $type renewals.";
  } elsif ($note =~ m!active/(.*)!) {
    $str = "This includes all active $type renewals through " .
           _date_string($1) .
           ".  It might not show all renewals past that date.";
  } else {
    $str = "This listing shows selected $type renewals, and should not ".
           "be considered complete.";
  }
  print "<p><em>$str</em></p>\n";
}

sub _print_citation_info {
  my ($self, $json, $headline) = @_;
  if ($headline) {
    print "<h3>Page information</h3>\n";
    print "<table>";
  }
  if ($json->{"responsibility"}) {
    my $value  = $self->_display_person($json->{"responsibility"});
    print $self->_tabrow(attr=>"Page responsibility", value=>$value);
  }
  if ($json->{"acknowledgement"}) {
    my $value = OLBP::html_encode($json->{"acknowledgement"});
    print $self->_tabrow(attr=>"Acknowledgement", value=>$value);
  }
  if ($json->{"last-updated"}) {
    my $value = OLBP::html_encode(_date_string($json->{"last-updated"}));
    print $self->_tabrow(attr=>"Last updated", value=>$value);
  }
  my $value = qq!<a href="?format=json">JSON</a>!;
  print $self->_tabrow(attr=>"Machine-readable format", value=>$value);
}

sub display_json {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $path = $self->{dir} . $fname . ".json";
  if ($params{pretty}) {
    my $json = $self->_readjsonfile($path);
    if ($json) {
      print $self->{parser}->pretty->encode($json);
    }
  } else {
    # print it raw
    my $str = "";
    open my $fh, "< $path" or return undef;
    while (<$fh>) {
      $str .= $_;
    }
    close $fh;
    print $str;
  }
}

sub _online_link {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $json = $params{json};
  my $uri = $serialprefix . $fname;
  if ($json->{"online"} =~ /http/) {
    $uri = $json->{"online"};
  } elsif ($json->{"online"} =~ /[A-Za-z]/) {
    $uri = $serialprefix . $json->{online};
  }
  return $uri;
}

sub _more_details_warranted {
  my ($json) = @_;
  return 1 if ($json->{"contents"});
  return 1 if ($json->{"renewed-issues"});
  return 1 if ($json->{"renewed-contributions"});
  return 1 if ($json->{"additional-note"});
  return 1 if ($json->{"additional-notes"});
  return 1 if ($json->{"first-issue"});
  return 1 if ($json->{"first-autorenewed-issue"});
  return 1 if ($json->{"website"});
  return 1 if ($json->{"see-also"});
  return 1 if ($json->{"preceded-by"});
  return 1 if ($json->{"succeeded-by"});
  return 0;
}

# This is what gets called on pages

sub serial_copyright_summary {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $path = $self->{dir} . $fname . ".json";
  # return "I'm trying to get $path.";
  my $json = $self->_readjsonfile($path);
  my $offerdetails = 0;
  return undef if (!$json);
  if (_more_details_warranted($json)) {
     $offerdetails = 1;
  }
  my $firstrenew = _get_first_renewed_issue($json);
  my $firstcont = _get_first_renewed_contribution($json);
  my $completeness = $json->{"renewed-issue-completeness"};
  my $overallrights = $json->{"rights-statement"};
  my $str = "";
  if ($overallrights eq $PDUS) {
    $str = "All content of this serial is in the public domain in the US";
  } elsif ($overallrights eq $COPYRIGHTED) {
    $str = "All content of this serial is copyrighted";
  }
  if ($firstrenew eq "none") {
    $str .= _display_no(completeness=>$completeness,
                        context=>"serialpage",
                        firstcont=>$firstcont);
  } elsif ($firstrenew) {
    $str .= "The first ";
    if ($completeness =~ /^active\//) {
      $str .= "actively ";
    }
    $str .= "copyright-renewed issue is ";
    $str .= _display_issue(issue=>$firstrenew);
    $offerdetails = 1;
  }
  if ($firstcont) {
   if ($firstrenew && !($firstrenew eq "none" && $firstcont eq "none")) {
     $str .= ". ";
   }
   if ($firstcont eq "none") {
     # TODO: MAKE THIS MORE DETAILED WITH SOURCES
     if ($firstrenew ne "none") {
       $str .= "We know of no actively copyright-renewed contributions";
     }
   } else {
     $str .= "The first ";
     if ($completeness =~ /^active\//) {
       $str .= "actively ";
     }
     $str .= "copyright-renewed contribution is from ";
     if ($firstcont->{"issue"}) {
       $firstcont = $firstcont->{"issue"};
     }
     $str .= _display_issue(issue=>$firstcont);
     $offerdetails = 1;
   }
  }
  $str .= ".";
  if ($offerdetails) {
    my $uri = $cinfoprefix . $fname;
    $str .= qq! (<a href="$uri">More details</a>)!;
  }
  return $str;
}

my $SOMEYEAR = -1;

# utility function that returns a year in a string if clearly stated
# or $SOMEYEAR (which should be less than any valid year and nonzero)
# if it can't find one

sub _getyear {
  my ($str) = @_;
  if ($str =~ /^(\d\d\d\d)/) {
    return $1;
  }
  return $SOMEYEAR;
}


# This just gives the first year of active renewal
#  (or $OLBP::CopyrightInfo::NO_RENEWAL if no renewal
#   or $OLBP::CopyrightInfo::UNCLEAR_RENEWAL if it sees a renewal
#     but can't figure out the year),
#  Returns undef if no record found.
#  This works strictly on the renewal fields in the record;
#    we do not attempt here to go to other related records
#    or add asterisks or other notations based on other fields

sub firstrenewal_year {
  my ($self, %params) = @_;
  my $json = $params{json};
  if (!$json) {
    $json = $self->get_json(%params);
  }
  return undef if (!$json);
  if ($json->{"rights-statement"} eq $PDUS) {
     return $OLBP::CopyrightInfo::ALL_PD;
  } elsif ($json->{"rights-statement"} eq $COPYRIGHTED) {
     return $OLBP::CopyrightInfo::ALL_COPYRIGHTED;
  } else {
    my $NOYEAR = 9999;
    my $firstautoissue = $json->{"first-autorenewed-issue"};
    my $firstissue = _get_first_renewed_issue($json);
    my $contissue;
    my $firstcont = _get_first_renewed_contribution($json);
    if ($firstcont && ref($firstcont)) {
       #  Accommodate old version of first-contribution-renewal w/o "issue"
      $contissue = $firstcont->{"issue"} || $firstcont;
    }
    my $firstyear = $NOYEAR;
    foreach my $issue ($firstautoissue, $firstissue, $contissue) {
      next if (!$issue || $issue eq "none");
      my $date = $issue->{"issue-date"};
      if ($date && _getyear($date) < $firstyear) {
        $firstyear = _getyear($date);
      }
      $date = $issue->{"cdate"};
      if ($date && _getyear($date) < $firstyear) {
        $firstyear = _getyear($date);
      }
    }
    if ($firstyear == $NOYEAR) {
      return $OLBP::CopyrightInfo::NO_RENEWAL;
    } elsif ($firstyear == $SOMEYEAR) {
      return $OLBP::CopyrightInfo::UNCLEAR_RENEWAL;
    } else {
      return $firstyear;
    }
  }
}

# Returns a list holding the additional notes.
# If none, returns an empty list.

sub additional_notes {
  my ($self, %params) = @_;
  my $json = $params{json};
  if (!$json) {
    $json = $self->get_json(%params);
  }
  if ($json->{"additional-notes"}) {
    return @{$json->{"additional-notes"}};
  }
  if ($json->{"additional-note"}) {
    return ($json->{"additional-note"});
  }
  return ();
}

# utility routine for returning a list of the IDs in a given
sub _idlist {
  my ($jsonfragment) = @_;
  my @list = ();
  return () if (!$jsonfragment);
  foreach my $item (@{$jsonfragment}) {
    if ($item->{id}) {
      push @list, $item->{id};
    }
  }
  return @list;
}

sub _idlist_fetch {
  my ($self, $what, %params) = @_;
  my $json = $params{json};
  if (!$json) {
    $json = $self->get_json(%params);
  }
  return () if (!$json);
  return _idlist($json->{$what});
}

sub preceding_ids {
  my ($self, %params) = @_;
  return $self->_idlist_fetch("preceded-by", %params);
}

sub succeeding_ids {
  my ($self, %params) = @_;
  return $self->_idlist_fetch("succeeded-by", %params);
}

sub related_ids {
  my ($self, %params) = @_;
  return $self->_idlist_fetch("see-also", %params);
}

sub firstperiod_reference {
  my ($self, %params) = @_;
  my $id = $params{id};
  my $fname = $id;
  $fname =~ s/[^A-Za-z0-9\-]//g;     # sanitize input
  my $path = $self->{dir} . $fname . ".json";
  my $json = $self->_readjsonfile($path);
  return "^" . $id . "^" if (!$json);
  my $worktitle = $json->{"title"};
  my $str = "";
  my $uri = $cinfoprefix . $fname;
  $str = qq!<a href="$uri">! .
           "<cite>" . OLBP::html_encode($worktitle) . "</cite>";
  if ($json->{"online"}) {
    $str = qq!<strong>$str</strong>!;
  }
  $str .= "</a>";
  if ($json->{"title-note"}) {
    $str .= " (" . OLBP::html_encode($json->{"title-note"}) . ")";
  }
  return $str;
}

sub get_json {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  $fname =~ s/[^A-Za-z0-9\-]//g;     # sanitize input
  my $path = $self->{dir} . $fname . ".json";
  return $self->_readjsonfile($path);
}

sub _rights_explanation {
  my ($str) = @_;
  if ($str eq $PDUS) {
    $str = "All content public domain in the US";
  } elsif ($str eq $COPYRIGHTED) {
    $str = "All content under copyright";
  }
  return $str;
}

sub firstperiod_listing {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $path = $self->{dir} . $fname . ".json";
  my $json = $self->_readjsonfile($path);
  return undef if (!$json);
  my $worktitle = $json->{"title"};
  return undef if (!$worktitle);
  my $str = "";
  my $uri = $cinfoprefix . $fname;
  $str = qq!<a href="$uri">! .
           "<cite>" . OLBP::html_encode($worktitle) . "</cite></a>";
  if ($json->{"online"}) {
    $str = qq!<strong>$str</strong>!;
  }
  if ($json->{"title-note"}) {
    $str .= " (" . OLBP::html_encode($json->{"title-note"}) . ")";
  }
  $str .= ": ";
  my $overallrights = $json->{"rights-statement"};
  my $skiprenewalnotes = 0;
  if ($overallrights eq $PDUS || $overallrights eq $COPYRIGHTED) {
    $str .= _rights_explanation($overallrights);
    $skiprenewalnotes = 1;
  }
  my $firstrenew = _get_first_renewed_issue($json);
  my $firstcont = _get_first_renewed_contribution($json);
  if ($firstrenew && !$skiprenewalnotes) {
    my $completeness = $json->{"renewed-issue-completeness"};
    if ($firstrenew eq "none") {
      $str .= _display_no(completeness=>$completeness,
                          source=>$json->{"first-renewed-issue-source"});
    } else {
      if ($completeness =~ /^active\//) {
        $str .= "issues actively renewed from ";
      } else {
        $str .= "issues renewed from ";
      }
      $str .= _display_issue(issue=>$firstrenew);
      $str .= _get_source_note($json, "first-renewed-issue-source",
                                      "first-renewed-issue", 1);
    }
    if ($firstcont) {
      $str .= "; ";
    }
  }
  if ($firstcont && !$skiprenewalnotes) {
    if ($firstcont eq "none") {
        $str .= _display_no(what=>"contribution",
                            completeness=>$json->{"first-renewed-contribution-completeness"}, 
                            source=>$json->{"first-renewed-contribution-source"});
    } else {
      if ($json->{"renewed-contribution-completeness"} =~ /^active\//) {
        $str .= "contributions actively renewed from ";
      } else {
        $str .= "contributions renewed from ";
      }
      if ($firstcont->{"issue"}) {
        $firstcont = $firstcont->{"issue"};
      }
      $str .= _display_issue(issue=>$firstcont);
      $str .= _get_source_note($json, "first-renewed-contribution-source",
                                      "first-renewed-contribution", 1);
    }
  }
  if ($json->{"preceded-by"}) {
    my @links = $self->_link_list($json->{"preceded-by"});
    $str .= "; preceded by " . join(", ", @links);
  }
  if ($json->{"succeeded-by"}) {
    my @links = $self->_link_list($json->{"succeeded-by"});
    $str .= "; succeeded by " . join(", ", @links);
  }
  if ($json->{"see-also"}) {
    my @links = $self->_link_list($json->{"see-also"});
    $str .= "; see also " . join(", ", @links);
  }
  return $str;
}

sub display_olbp_cover {
  my ($self, %params) = @_;
  my $json = {};
  $json->{"title"} = $params{title};
  $json->{"online"} = 1;
  $json->{"suggest-cinfo"} = 1;
  return $self->display_page(filename=>$params{id}, json=>$json);
}

sub _creator_list {
  my ($self, $role, @creators) = @_;
  my $str = ",";
  if ($role) {
    $str .= " $role";
  }
  $str .= " by ";
  for (my $i = 0; $i < scalar @creators; $i++) {
    $str .= $self->_display_person($creators[$i]);
    if ($i < scalar(@creators) - 1) {
      if ($i < scalar(@creators) - 2) {
        $str .= ", ";
      } else {
        $str .= " and ";
      }
    }
  }
  return $str;
}

sub display_page {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $json = $params{json};
  print qq^<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8">
<link rel="stylesheet" type="text/css" href="$OLBP::styleurl" />
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style type="text/css">
  p.ctr {text-align: center}
  h1 {text-align: center}
  h2 {text-align: center}
  h3 {text-align: center}
</style>
^;
  if (!$json) {
    my $path = $self->{dir} . $fname . ".json";
    $json = $self->_readjsonfile($path);
  }
  _errorpage("Could not parse JSON") if (!$json);
  my $worktitle = $json->{"title"};
  _errorpage("Could not get title") if (!$worktitle);
  print "<title>" . OLBP::html_encode($worktitle);
  print " copyright information</title></head>";
  print "<h1>" . OLBP::html_encode($worktitle) . "</h1>\n";
  print "<h2>Copyright information</h2>\n";
  
  print "<table>";
  print $self->_tabrow(attr=>"Title",
                       value=>"<cite>" . OLBP::html_encode($worktitle) .
                              "</cite>");
  if ($json->{"title-note"}) {
    print $self->_tabrow(attr=>"Title note",
                         value=>OLBP::html_encode($json->{"title-note"}));
  }
  if ($json->{"aka"}) {
    print $self->_tabrow(attr=>"Also known as",
                          value=>_encode_list($json->{"aka"}, "; "));
  }
  if ($json->{"online"}) {
     my $note = "Free online material via The Online Books Page";
     my $uri = $self->_online_link(filename=>$fname, json=>$json);
     if ($json->{"online"} =~ /http/ && !($json->{"online"} =~ /onlinebooks/)) {
       $note = "Link";
     }
     my $link = qq!<a href="$uri"><strong>$note</strong></a>!;
     print $self->_tabrow(attr=>"Online content", value=>$link);
  }
  if ($json->{"website"} && $json->{"website"}->{"url"}) {
    my $note = $json->{"website"}->{"note"} || "Official site";
    $note = OLBP::html_encode($note);
    my $uri = $json->{"website"}->{"url"};
    my $link = qq!<a href="$uri">$note</a>!;
    print $self->_tabrow(attr=>"Web site", value=>$link);
  }
  if ($json->{"contents"}) {
    my @links = $self->_link_list($json->{"contents"}, "Contents listing");
    if (@links) {
      print $self->_tabrow(attr=>"Tables of contents",
                                  value=>join(", ", @links));
    }
  }
  if ($self->{wdsource}) {
    my $wikidata = $self->{wdsource}->get_wikidata_uri(id=>$fname);
    my $wikipedia = $self->{wdsource}->get_wikipedia_uri(id=>$fname);
    if ($wikidata) {
      $wikidata = qq!<a href="$wikidata">Wikidata</a>!;
    }
    if ($wikipedia) {
      $wikipedia = qq!<a href="$wikipedia">Wikipedia article</a>!;
    }
    if ($wikidata || $wikipedia) {
      my $value = $wikidata;
      if ($wikipedia) {
         $value = $wikipedia . "; " . $value;
      }
      print $self->_tabrow(attr=>"More information", value=>$value);
    }
  }
  if ($json->{"preceded-by"}) {
    my @links = $self->_link_list($json->{"preceded-by"});
    if (@links) {
      print $self->_tabrow(attr=>"Preceded by",
                                  value=>join(", ", @links));
    }
  }
  if ($json->{"first-issue"}) {
    print $self->_tabrow(attr=>"First issue",
                        value=>_display_issue(issue=>$json->{"first-issue"}));
  }
  my $firstrenew = _get_first_renewed_issue($json);
  if ($json->{"rights-statement"}) {
    my $statement = _rights_explanation($json->{"rights-statement"});
    print $self->_tabrow(attr=>"Rights", value=>$statement);
  }
  if ($firstrenew) {
    my $label = "First renewed issue";
    my $value = "";
    my $completeness = $json->{"renewed-issue-completeness"};
    if ($completeness =~ /^active\//) {
      my $label = "First active issue renewal";
    }
    if ($firstrenew eq "none") {
      $value = _display_no(completeness=>$completeness,
                           source=>$json->{"first-renewed-issue-source"});
    } else {
      $value = _display_issue(issue=>$firstrenew);
      $value .= _get_source_note($json, "first-renewed-issue-source",
                                 "first-renewed-issue");
    }
    print $self->_tabrow(attr=>$label, value=>$value);
  }
  if ($json->{"first-autorenewed-issue"}) {
    print $self->_tabrow(attr=>"First automatically renewed issue",
                         value=>_display_issue(
                          issue=>$json->{"first-autorenewed-issue"}));
  }
  $firstrenew = _get_first_renewed_contribution($json);
  if ($firstrenew) {
    my $label = "First renewed contribution in";
    if ($json->{"renewed-contribution-completeness"} =~ /^active\//) {
      my $label = "First active contribution renewal in";
    }
    my $value = "";
    if ($firstrenew eq "none") {
        $value .= _display_no(what=>"contribution",
              completeness=>$json->{"first-renewed-contribution-completeness"}, 
              source=>$json->{"first-renewed-contribution-source"});
    } else {
      if ($firstrenew->{"issue"}) {
        $firstrenew = $firstrenew->{"issue"};
      }
      $value = _display_issue(issue=>$firstrenew);
      $value .= _get_source_note($json, "first-renewed-contribution-source",
                                        "first-renewed-contribution");
    }
    print $self->_tabrow(attr=>$label, value=>$value);
  }
  if ($json->{"last-issue"}) {
    print $self->_tabrow(attr=>"Last issue",
                        value=>_display_issue(issue=>$json->{"last-issue"}));
  }
  if ($json->{"succeeded-by"}) {
    my @links = $self->_link_list($json->{"succeeded-by"});
    if (@links) {
      print $self->_tabrow(attr=>"Succeeded by",
                                  value=>join(", ", @links));
    }
  }
  if ($json->{"see-also"}) {
    my @links = $self->_link_list($json->{"see-also"});
    if (@links) {
      print $self->_tabrow(attr=>"See also",
                                  value=>join(", ", @links));
    }
  }
  my $headline = 1;
  if ($json->{"renewed-issues"} || $json->{"renewed-contributions"}
      || $json->{"suggest-cinfo"}
      || $json->{"additional-note"} || $json->{"additional-notes"}) {
    print "</table>";
    if ($json->{"renewed-issues"}) {
       print "<h3>Renewed issues</h3>\n";
       _print_completeness_note($json->{"renewed-issue-completeness"},
                                "issue");
       print "<ul>\n";
       my $str = "";
       foreach my $issue (@{$json->{"renewed-issues"}}) {
         $str = _display_issue(issue=>$issue, bolddate=>1);
         print "<li> $str";
       }
       print "</ul>\n";
    }
    if ($json->{"renewed-contributions"}) {
       print "<h3>Renewed contributions</h3>\n";
       _print_completeness_note($json->{"renewed-contribution-completeness"},
                                "contribution");
       print "<ul>\n";
       my $str = "";
       foreach my $contr (@{$json->{"renewed-contributions"}}) {
         my $issue = $contr->{"issue"};
         if ($issue) {
           $str = _display_issue(issue=>$issue, bolddate=>1) . ": ";
         }
         if ($contr->{"title"}) {
           $str .= '"' . OLBP::html_encode($contr->{"title"}) . '"';
         }
         if ($contr->{"title-note"}) {
           $str .= ' (' . OLBP::html_encode($contr->{"title-note"}) . ')';
         }
         if ($contr->{"author"}) {
           $str .= ", by " . $self->_display_person($contr->{"author"});
         } elsif ($contr->{"authors"}) {
           $str .= $self->_creator_list("", @{$contr->{"authors"}});
         }
         if ($contr->{"editor"}) {
           $str .= ", ed. by " . $self->_display_person($contr->{"editor"});
         }
         if ($contr->{"illustrator"}) {
           $str .=
              ", ill. by " . $self->_display_person($contr->{"illustrator"});
         }
         if ($contr->{"translator"}) {
           $str .= ", trans. by " .
               $self->_display_person($contr->{"translator"});
         } elsif ($contr->{"translators"}) {
           $str .= $self->_creator_list("trans.", @{$contr->{"translators"}});
         }
         if ($contr->{"note"}) {
           $str .= ' (' . OLBP::html_encode($contr->{"note"}) . ')';
         }
         print "<li> $str";
       }
       print "</ul>\n";
    }
    if ($json->{"additional-note"}) {
       print "<h3>Additional note</h3>\n";
       print "<p>" . OLBP::html_encode($json->{"additional-note"}) . "</p>\n";
    } elsif ($json->{"additional-notes"}) {
       print "<h3>Additional notes</h3>\n";
       foreach my $note (@{$json->{"additional-notes"}}) {
         print "<p>" . OLBP::html_encode($note) . "</p>\n";
       }
    } elsif ($json->{"suggest-cinfo"}) {
      my $infouri = $inforeqprefix;
      $infouri .= "&qtitle=" . OLBP::url_encode($worktitle);
      print qq!<p>We have no copyright information on this title,
        but we link to some of its content online.  You can
        <a href="$infouri">request or provide more information on it</a>
        if you like.
        </p>
      !;
    }
  } else {
    $headline = 0;
  }
  if (!$json->{"suggest-cinfo"}) {
    $self->_print_citation_info($json, $headline);
    print "</table>";
  }
  print "<p><em>$disclaimer</em></p>\n";
  my @choices = ("Copyright registration and renewal records" => $cceurl,
                 "First periodical renewals"    => $firstperiodurl,
                 "Deep backfile knowledge base"    => $backfileurl);
  print OLBP::choicelist(undef, @choices);
  print $OLBP::copyrcc0bodyend;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{arfile} = $params{arfile};
  $self->{wdsource} = $params{wdsource};
  $self->{parser} = JSON->new->allow_nonref;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

