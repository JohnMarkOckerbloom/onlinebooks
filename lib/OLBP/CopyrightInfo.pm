package OLBP::CopyrightInfo;
use strict;
use JSON;

my $serialprefix = "http://onlinebooks.library.upenn.edu/webbin/serial?id=";
my $cinfoprefix = "http://onlinebooks.library.upenn.edu/webbin/cinfo/";
my $codburl = "http://cocatalog.loc.gov/";
my $cceurl  = "http://onlinebooks.library.upenn.edu/cce/";

my @month = ("January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December");

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
  my ($listref) = @_;
  my @newlist;
  foreach my $name (@{$listref}) {
    push @newlist, OLBP::html_encode($name);
  }
  return join (", ", @newlist);
}

sub _tables_of_contents {
  my ($listref) = @_;
  my @links = ();
  foreach my $item (@{$listref}) {
    if ($item->{"url"}) {
      my $note = $item->{"note"} || "Contents listing";
      push @links, qq!<a href="$item->{url}">$note</a>!;
    }
  }
  return @links;
}

sub _date_string {
  my ($date) = @_;
  if ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
    return $month[$2-1] . " " . int($3) . ", $1";
  }
  if ($date =~ /^(\d\d\d\d)-(\d\d)$/) {
    return $month[$2-1] . " $1";
  }
  if ($date =~ /^(\d\d\d\d)-(\.*)$/) {
    return "$2 $1";
  }
  return $date;
}

sub _number_string {
  my ($number) = @_;
  if (int($number)) {
    return "no. " . OLBP::html_encode($number);
  }
  # not a number, but an issue title.  Return literally.
  return OLBP::html_encode($number);
}

sub _display_no_issue {
  my (%params) = @_;
  my $completeness = $params{completeness};
  my $context = $params{context};
  my $active = (($params{completeness} =~ /^active\//) ? " active" : "");
  my $source = $params{source};
  my $str = "";
  if ($context eq "serialpage") {
    $str = "No$active issue ";
    if ($params{firstcont} && $params{firstcont} eq "none") {
      $str .= "or contribution ";
    }
    $str .= "copyright renewals were found";
  } else {
    $str = "no$active issue renewals found";
  }
  if ($context eq "serialpage") {
    $str .= " for this serial";
    return $str;
  }
  if ($source eq "cce") {
    $str .= " in CCE";
  } elsif ($source eq "cce+database") {
    $str .= " in CCE or registered works database";
  } elsif ($source eq "database") {
    $str .= " in registered works database";
  }
  return $str;
}

sub _display_issue {
  my (%params) = @_;
  my $issue = $params{issue};
  my $str = "";
  return "" if (!$issue);
  if ($issue->{"issuedate"}) {
    $str = OLBP::html_encode(_date_string($issue->{"issuedate"}));
    if ($params{bolddate}) {
      $str = "<b>$str</b>";
    }
  }
  my $hasdate = $str;
  if ($issue->{"volume"} || $issue->{"number"}) {
    if ($hasdate) {
      $str .= " (";
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
  if ($person->{"authorized"}) {
    $str = OLBP::html_encode(_informalname($person->{"authorized"}));
  } elsif ($person->{"name"}) {
    $str = OLBP::html_encode($person->{"name"});
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
  if ($json->{"first-renewedissue"}) {
    return $json->{"first-renewedissue"};
  }
  if ($json->{"renewedissue-completeness"} =~ /^active\//) {
    if ($json->{"renewedissues"}) {
      return $json->{"renewedissues"}->[0];
    }
  }
  return undef;
}

sub _get_first_renewed_contribution {
  my ($json) = @_;
  if ($json->{"first-renewedcontribution"}) {
    return $json->{"first-renewedcontribution"};
  }
  if ($json->{"renewedcontribution-completeness"} =~ /^active\//) {
    if ($json->{"renewedcontributions"}) {
      return $json->{"renewedcontributions"}->[0];
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
    if ($what->{"issuedate"}) {
      $what = $what->{"issuedate"};
    } elsif ($what->{"issue"} && $what->{"issue"}->{"issuedate"}) {
      $what = $what->{"issue"}->{"issuedate"};
    }
    if ($what && $what gt "1950" && $what lt "1964") {
      $source = "database";
    }
  }
  return "" if (!$source);
  if ($source eq "database") {
    if ($nolink) {
      return qq!; see registered works database!;
    }
    return qq!; see <a href="$codburl">registered works database</a>!;
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
      return qq!; see <a href="$catpageurl">$year</a> !
            . OLBP::html_encode($rest);
    }
    return "; see " . OLBP::html_encode("$year $rest");
  }
  if ($source) {
    return qq"; see " . OLBP::html_encode($source);
  }
  return "";
}

sub _print_completeness_note {
  my ($note) = @_;
  my $str = "";
  if ($note eq "active/autorenewals") {
    $str = "This includes all active renewals prior to " .
           " 1964, when automatic renewals began.  It might not show all" .
           " renewals from 1964 onward."
  } elsif ($note =~ m!active/(.*)!) {
    $str = "This includes all active renewals through " .
           _date_string($1) .
           ".  It might not show all renewals past that date."
  } else {
    $str = "This listing shows selected renewals, and should not ".
           "be considered complete.";
  }
  print "<p><em>$str</em></p>\n";
}

sub _print_citation_info {
  my ($self, $json, $headline) = @_;
  # TODO: Credits
  if ($headline) {
    print "<h3>Page information</h3>\n";
    print "<table>";
  }
  if ($json->{"responsibility"}) {
    my $value  = $self->_display_person($json->{"responsibility"});
    print $self->_tabrow(attr=>"Page responsibility", value=>$value);
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
  return 1 if ($json->{"renewedissues"});
  return 1 if ($json->{"renewedcontributions"});
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
  my $firstrenew = _get_first_renewed_issue($json);
  my $firstcont = _get_first_renewed_contribution($json);
  my $completeness = $json->{"renewedissue-completeness"};
  my $str = "";
  if ($firstrenew eq "none") {
    $str .= _display_no_issue(completeness=>$completeness,
                              context=>"serialpage",
                              firstcont=>$firstcont);
  } elsif ($firstrenew) {
    $str .= "The first ";
    if ($completeness =~ /^active\//) {
      $str .= "actively ";
    }
    $str .= "renewed issue is ";
    $str .= _display_issue(issue=>$firstrenew);
    $offerdetails = 1;
  }
  if ($firstcont) {
    if (!($firstrenew eq "none" && $firstcont eq "none")) {
      if ($firstrenew) {
        $str .= ". ";
      }
    }
    if ($firstcont eq "none") {
      # TODO: MAKE THIS MORE DETAILED WITH SOURCES
      $str .= "We know of no actively renewed contributions";
    } else {
      $str .= "The first ";
      if ($completeness =~ /^active\//) {
        $str .= "actively ";
      }
      $str .= "renewed contribution is from ";
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


sub firstperiod_listing {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  my $path = $self->{dir} . $fname . ".json";
  my $json = $self->_readjsonfile($path);
  return undef if (!$json);
  my $worktitle = $json->{"title"};
  return undef if (!$worktitle);
  my $str = "";
  if ($json->{"online"}) {
    my $uri = $self->_online_link(filename=>$fname, json=>$json);
    $str = qq!<a href="$uri">! .
           "<cite>" . OLBP::html_encode($worktitle) . "</cite></a>";
  } else {
    $str = "<cite>" . OLBP::html_encode($worktitle) . "</cite>";
  }
  if ($json->{"title-note"}) {
    $str .= " (" . OLBP::html_encode($json->{"title-note"}) . ")";
  }
  $str .= ": ";
  my $firstrenew = _get_first_renewed_issue($json);
  my $firstcont = _get_first_renewed_contribution($json);
  if ($firstrenew) {
    my $completeness = $json->{"renewedissue-completeness"};
    if ($firstrenew eq "none") {
      $str .= _display_no_issue(completeness=>$completeness,
                                source=>$json->{"first-renewedissue-source"});
    } else {
      if ($completeness =~ /^active\//) {
        $str .= "issues actively renewed from ";
      } else {
        $str .= "issues renewed from ";
      }
      $str .= _display_issue(issue=>$firstrenew);
      $str .= _get_source_note($json, "first-renewedissue-source",
                                      "first-renewedissue", 1);
    }
    if ($firstcont) {
      $str .= "; ";
    }
  }
  if ($firstcont) {
    if ($json->{"renewedcontribution-completeness"} =~ /^active\//) {
      $str .= "contributions actively renewed from ";
    } else {
      $str .= "contributions renewed from ";
    }
    if ($firstcont->{"issue"}) {
      $firstcont = $firstcont->{"issue"};
    }
    $str .= _display_issue(issue=>$firstcont);
    $str .= _get_source_note($json, "first-renewedcontribution-source",
                                    "first-renewedcontribution", 1);
  }
  if (_more_details_warranted($json)) {
    my $uri = $cinfoprefix . $fname;
    $str .= qq! (<a href="$uri">More details</a>)!;
  }
  return $str;
}

sub display_page {
  my ($self, %params) = @_;
  my $fname = $params{filename};
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
  my $path = $self->{dir} . $fname . ".json";
  my $json = $self->_readjsonfile($path);
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
                          value=>_encode_list($json->{"aka"}));
  }
  if ($json->{"online"}) {
     my $note = "Free online material via The Online Books Page";
     my $uri = $self->_online_link(filename=>$fname, json=>$json);
     if ($json->{"online"} =~ /http/) {
       my $note = "Link";
     }
     my $link = qq!<a href="$uri">$note</a>!;
     print $self->_tabrow(attr=>"Online content", value=>$link);
  }
  if ($json->{"contents"}) {
    my @links = _tables_of_contents($json->{"contents"});
    if (@links) {
      print $self->_tabrow(attr=>"Tables of contents",
                                  value=>join(", ", @links));
    }
  }
  if ($json->{"first-issue"}) {
    print $self->_tabrow(attr=>"First issue",
                        value=>_display_issue(issue=>$json->{"first-issue"}));
  }
  my $firstrenew = _get_first_renewed_issue($json);
  if ($firstrenew) {
    my $label = "First renewed issue";
    my $value = "";
    my $completeness = $json->{"renewedissue-completeness"};
    if ($completeness =~ /^active\//) {
      my $label = "First active issue renewal";
    }
    if ($firstrenew eq "none") {
      $value = _display_no_issue(completeness=>$completeness,
                                 source=>$json->{"first-renewedissue-source"});
    } else {
      $value = _display_issue(issue=>$firstrenew);
      $value .= _get_source_note($json, "first-renewedissue-source",
                                 "first-renewedissue");
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
    if ($json->{"renewedcontribution-completeness"} =~ /^active\//) {
      my $label = "First active contribution renewal in";
    }
    if ($firstrenew->{"issue"}) {
      $firstrenew = $firstrenew->{"issue"};
    }
    my $value = _display_issue(issue=>$firstrenew);
    $value .= _get_source_note($json, "first-renewedcontribution-source",
                               "first-renewedcontribution");
    print $self->_tabrow(attr=>$label, value=>$value);
  }
  if ($json->{"renewedissues"} || $json->{"renewedcontributions"}) {
    print "</table>";
    if ($json->{"renewedissues"}) {
       print "<h3>Renewed issues</h3>\n";
       _print_completeness_note($json->{"renewedissue-completeness"});
       print "<ul>\n";
       my $str = "";
       foreach my $issue (@{$json->{"renewedissues"}}) {
         $str = _display_issue(issue=>$issue, bolddate=>1);
         print "<li> $str";
       }
       print "</ul>\n";
    }
    if ($json->{"renewedcontributions"}) {
       print "<h3>Renewed contributions</h3>\n";
       _print_completeness_note($json->{"renewedcontribution-completeness"});
       print "<ul>\n";
       my $str = "";
       foreach my $contr (@{$json->{"renewedcontributions"}}) {
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
           $str .= ", by ";
           my @authorlist = @{$contr->{"authors"}};
           for (my $i = 0; $i < scalar @authorlist; $i++) {
             $str .= $self->_display_person($authorlist[$i]);
             if ($i < scalar(@authorlist) - 1) {
               if ($i < scalar(@authorlist) - 2) {
                 $str .= ", ";
               } else {
                 $str .= " and ";
               }
             }
           }
         }
         if ($contr->{"note"}) {
           $str .= ' (' . OLBP::html_encode($contr->{"note"}) . ')';
         }
         print "<li> $str";
       }
       print "</ul>\n";
    }
  }
  $self->_print_citation_info($json,
              ($json->{"renewedissues"} || $json->{"renewedcontributions"}));
  print "</table>";
  print "<p><em>$disclaimer</em></p>\n";
  print $OLBP::bodyend;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{arfile} = $params{arfile};
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
