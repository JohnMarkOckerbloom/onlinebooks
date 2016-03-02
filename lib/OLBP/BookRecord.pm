package OLBP::BookRecord;
use strict;
use OLBP::Entities;

my %ROLEABBR = ("EDITOR" => "ed.", "TRANSLATOR" => "trans.",
                "CONTRIBUTOR" => "contrib.", "ILLUSTRATOR" => "illust.");

my @month = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
             "Aug", "Sep", "Oct", "Nov", "Dec");

my %mcode = ("Jan" => 1, "Feb" => 2,  "Mar" => 3,  "Apr" => 4,
             "May" => 5, "Jun" => 6,  "Jul" => 7,  "Aug" => 8,
             "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12);

my $idnum = 0;

my $AUTHORNAMESEP = "\x02";
# my $AUTHORTITLESEP = "\x01";

sub _genid {
  return "_i" . $idnum++;
}

my $SDISCLAIMER = qq!
<i>
The subject above was assigned automatically to this book
based on its call number.  It may be imprecise, incomplete, or inaccurate.
If this book should be more precisely described, please let us know.
</i>
!;

$OLBP::BookRecord::error = "";

sub _formaterror {
  $OLBP::BookRecord::error = shift;
  return 0;
}

# for REF links and the like, some &'s and the like might already be escaped
# so we unescape them first, and then escape the usual way
# (URLs without escaped links should just be escaped normally)

sub _ref_link_encode {
  my $str = shift;
  $str =~ s/&gt;/>/g;
  $str =~ s/&lt;/</g;
  $str =~ s/&amp;/&/g;
  return OLBP::html_encode($str);
}

sub get_format_error { return $OLBP::BookRecord::error;}

sub _booknote {
  my $self = shift;
  my $note = $self->{NOTE};
  return "" if (!$note);
  if (@{$self->{REF}} || !($note =~ /^see (.*)/i)) {
    return " ($note)";
  }
  my $xref = $1;
  my $rest;
  my $reftype = (($self->{title}) ? "title" : "author");
  my $str = " (see ";
  if ($xref =~ /^also (.*)/) {
    $xref = $1;
    $str .= "also ";
  }
  $str .= "<a href=\"" . $OLBP::scripturl . "/search?" . substr($reftype, 0, 1);
  $str .= "mode=start\&amp;$reftype=";
  # the cross-ref. is everything before an open paren
  if ($xref =~ /^([^\(]*)(\(.*)$/) {
    $xref = $1;
    $rest = $2;
  }
  $str .= OLBP::url_encode($xref) . "\">" . OLBP::html_encode($xref) . "</a>";
  if ($rest) {
    $str .= " $rest";
  }
  return $str . ")";
}

sub _titlewithnote {
  my ($self, $htmlify) = @_;
  my $str;
  if ($self->{notrealtitle} || !$htmlify) {
    $str .= $self->{title};
  } else {
    $str .= "<cite>" . $self->{title} . "</cite>";
  }
  if ($self->is_work()) {
    $str = "<strong>$str</strong>";
  }
  $str .= $self->_booknote();
  return $str;
}

# helper method to ignore date suffixes on single-part names
# (see below)

sub _isdatesuffix {
  my $s = shift;
  return (($s =~ /^[-\d\s]*$/) || ($s =~ /^\s*\d*-\d*\s+B\.\s*C\.\s*$/));
}

# informalname undoes the inversion of the "formal" name
# takes a string; this is NOT an OO method
# assumed to be the second part (part between first comma and next
# comma, bracket, or parenthesis, followed by a space, followed by 
# the part before the first comma
# but if the second part is a date suffix, just throw it out
# (e.g. "Voltaire, 1694-1778" -> "Voltaire", not "1694-1778 Voltaire")

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

# _isodate turns dates like "4 Jun 2000" into "2000-06-04"
# this it NOT an OO method

sub _isodate {
  my $str = shift;
  if ($str =~ /(\d+)\s+(\w\w\w).*\s+(\d+)/) {
    return sprintf("%04d-%02d-%02d", $3, $mcode{$2}, $1);
  }
  return 0;
}

# authorkey uncaps the name and removes all accents

sub _authorkey {
  my $name = shift;
  $name = OLBP::Entities::normalize_entities($name);
  $name = lc($name);
  # Remove quotes, apostrophes and terminal punctuation except for commas
  $name =~ s/["';:.?!]//g;
  # Change hyphens into spaces
  $name =~ s/-/ /g;
  $name =~ s/\s+/ /g;
  # Remove leading and trailing spaces
  $name =~ s/^ //;
  $name =~ s/ $//;
  return $name;
}

# for sort_key_for_name we also map commas to authornamesep
# (to make them file before other things)
# and we cap the size of the key
# This is not OO

sub sort_key_for_name {
  my $name = _authorkey(shift);
  $name =~ s/,/$AUTHORNAMESEP/g;
  return substr($name, 0, $OLBP::authorsortkeylimit);
  return $name;
}

# for search_key_for_name we eliminate commas and don't cap the key size
# This is not OO

sub search_key_for_name {
  my $name = _authorkey(shift);
  $name =~ s/,//g;
  return $name;
}

# These are not OO either

sub search_key_for_title {
  my $str = shift;
  $str = OLBP::Entities::normalize_entities($str);
  $str = lc($str);
  if ($str =~ /^(a |an |the )(.*)/) {
    $str = $2;
  }
  # Remove quotes, apostrophes and punctuation that tends to be terminal
  $str =~ s/["';:.?!,]//g;
  # Change hyphens into spaces
  $str =~ s/-/ /g;
  $str =~ s/\s+/ /g;
  return $str;
}

sub sort_key_for_title {
  return substr(search_key_for_title(shift), 0, $OLBP::titlesortkeylimit);
}

# sort_key_for_lccn pads the first number in the lccn to get proper ordering
# we also have to reflect the fact that 3 letter codes are *not* underneath
# the 2-letter codes -- we do this by adding an extra space to 2-letter codes
# replace this by: we place a space after the first letter cluster in general
# 
# We normalize the latter part of the key by always having
# a space and a dot separating digits from letters
# not an oo method


sub sort_key_for_lccn {
  my $str = uc(shift);
  # $str =~ s/^([A-Z][A-Z])([0-9]|$)/$1 $2/;
  $str =~ s/^([A-Z]+)([0-9])/$1 $2/;
  $str =~ s/(\d+)/sprintf("%08d", $1)/e;
  $str =~ s/(\d)\s*\.?([A-Z])/$1 .$2/g;
  return $str;
}

sub search_key_for_subject {
  my $str = shift;
  $str = OLBP::Entities::normalize_entities($str);
  $str = lc($str);
  $str =~ s/\.\s*$//;
  $str = substr($str, 0, $OLBP::subjectsortkeylimit);
  return $str;
}

sub sort_key_for_subject {
  my $str = shift;
  $str = search_key_for_subject($str);
  # Remove quotes, apostrophes and punctuation that tends to be terminal
  $str =~ s/["';:.?!,]//g;
  # Change hyphens into spaces (note that this ends up removing -- divisions)
  $str =~ s/-/ /g;
  $str =~ s/\s+/ /g;
  $str =~ s/\.\s*$//;
  return $str;
}

sub _creatorcredits {
  my ($self, %params) = @_;
  my @names = @{$self->{name}};
  my @roles = @{$self->{role}};
  my $numnames = scalar(@names);
  my $skip = $params{skip} - 1;
  my $str;
  if ($numnames) {
    my $i;
    my %bins;
    my $alsorole;
    for ($i = 0; $i < $numnames; $i++) {
      if ($i != $skip) {
        push @{$bins{$roles[$i]}}, $i;
      }
    }
    if ($skip >= 0) {
      $alsorole = $roles[$skip];
    }
    foreach my $key ("AUTHOR", "EDITOR", "TRANSLATOR",
                    "CONTRIBUTOR", "ILLUSTRATOR") {
      if ($bins{$key}) {
        my @bin = @{$bins{$key}};
        my $binsize = scalar(@bin);
        if ($binsize) {
          $str .= ", ";
          if ($key eq $alsorole) {
            $str .= "also ";
          }
          $str .= $ROLEABBR{$key} . " by " . $self->{informalname}->[$bin[0]];
          for ($i = 1; $i < $binsize; $i++) {
            if ($binsize > 2) {
              $str .= ", "
            }
            if ($i == $binsize - 1) {
              $str .= " and ";
            }
            $str .= $self->{informalname}->[$bin[$i]];
          }
        }
      }
    }
  }
  return $str;
}


sub is_serial { return shift->{serial};}
sub is_work { return shift->{workrec};}
sub get_title { return shift->{title};}
sub get_note { return shift->{NOTE};}
sub get_iso_date { return shift->{date};}
sub get_work { return shift->{EDOF};}

sub get_short_title {
  my $title = shift->{title};
  $title =~ s/: .*//;
  return $title;
}

# For RFC822 we have to add a time

sub get_rfc822_date {
  my $self = shift;
  my $str822 = "";
  if ($self->{date} =~ /(\d+)-(\d+)-(\d+)/) {
    $str822 = "DATE " . int($3) . " $month[$2-1] $1\n";
    $str822 .= " 00:00:01 GMT";
  }
  return $str822;
}

sub get_id {
  my $self = shift;
  if (!$self->{ID}) {
    $self->{ID} = _genid();
  }
  return $self->{ID};
}

sub get_names { return @{shift->{name}};}
sub get_roles { return @{shift->{role}};}
sub get_other_titles { return @{shift->{othertitles}};}

sub get_sets { return @{shift->{sets}};}

sub get_refs { return @{shift->{REF}};}
sub get_nonus_refs { return @{shift->{NUREF}};}

sub get_wdbrefs { return @{shift->{wdbref}};}

sub curated { return (shift->{ID} =~ /^olbp/)}

sub get_ref {
  my ($self, $idx) = @_;
  return $self->{REF}->[$idx];
}

sub get_stable_link {
  my $self = shift;
  my $id = $self->get_id();
  if ($id && !($id =~ /^_i/)) {   # not a temporary id
    my $slink = "lookupid?key=$id";
    return "$OLBP::scripturl/$slink";
  }
  return "";
}

sub get_lccn {
  my $lccn = shift->{LCCN};
  $lccn =~ s/\s*approximate\s*$//;
  return $lccn;
}


sub get_formal_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my $nameref = $self->{name};
  if ($nameref && @{$nameref}) {
    return $nameref->[$idx-1];
  }
}

sub get_informal_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my $nameref = $self->{informalname};
  if ($nameref && @{$nameref}) {
    return $nameref->[$idx-1];
  }
}

sub get_subjects {
  my ($self, %params) = @_;
  my $type = $params{type};
  my $subref = $self->{subject};
  return () if (!$subref);
  if (!$type) {
    return @{$subref};
  }
  my @list = ();
  for (my $i = 0; $subref->[$i]; $i++) {
    if ($type eq $self->{subjtype}->[$i]) { 
      push @list, $subref->[$i];
    }
  }
  return @list;
}

# returns probable publication year or 0 if not specified

sub _probable_publication_year {
  my ($self, %params) = @_;
  my $note = $self->{NOTE};
  if ($note =~ /(\d\d\d\d)\s*$/) {
    return $1;
  }
  if ($self->{serial} && $note =~ /(\d\d\d\d)-\s*$/) {
    # open-ended: might be present or not. Assume 2014
    return 2014;
  } elsif ($self->{serial} && $self->{SREF}) {
    my $max = 0;
    # see if we can find out from SREFs how far things extend
    foreach my $sref (@{$self->{SREF}}) {
      if ($sref =~ /^\S*-present/) {
        # let's assume present is 2015
        return 2015;
      } elsif ($sref =~ /\S*-recent/) {
        # let's assume recent is 2010
        $max = 2010 if ($max < 2010);
      } elsif ($sref =~ /^\S*(\d\d\d\d) /) {
        # take the last year in the SREF if later than current max
        $max = $1 if ($max < $1);
      }
    }
    return $max;
  }
  return 0;
}

# returns the score of the subject passed in, or 0 if not a subject
# We'll match on either the subject or the key

sub get_subject_score {
  my ($self, %params) = @_;
  my $subject = $params{subject};
  my $key = $params{key};
  return 0 if (!$self->{subject});
  for (my $i = 0; $i < scalar(@{$self->{subject}}); $i++) {
    if ($subject && $self->{subject}->[$i] eq $subject) {
      return $self->{subjscore}->[$i];
    }
    if ($key && search_key_for_subject($self->{subject}->[$i]) eq $key) {
      # print "$key: $self->{subjscore}->[$i]\n";
      return $self->{subjscore}->[$i];
    }
  }
  return 0;
}

sub get_title_sort_key {
  my $self = shift;
  my $key = $self->{tsortkey};
  if (!$key) {
    $key = sort_key_for_title($self->{title});
    $self->{tsortkey} = $key;
  }
  return $key;
} 

sub get_title_search_key {
  my $self = shift;
  my $key = $self->{tsearchkey};
  if (!$key) {
    $key = search_key_for_title($self->{title});
    $self->{tsearchkey} = $key;
  }
  return $key;
} 


sub get_lccn_sort_key {
  my $self = shift;
  my $key = $self->{lcsortkey};
  if (!$key) {
    my $lccn = $self->get_lccn();
    $key = sort_key_for_lccn($lccn);
    $self->{lcsortkey} = $key;
  }
  return $key;
} 

# get_title_subject returns the subject listing
# of a book.  If there's a TSUB we use that;
# otherwise, we take the first author
# and add the title onto it.

sub get_title_subject {
  my ($self, %params) = @_;
  if ($self->{TSUB}) {
    return $self->{TSUB};
  }
  my $str = "";
  my $author = $self->get_formal_name(index=>1);
  if ($author) {
    $str .= $author;
    if (!($str =~ /\.$/)) {
      $str .= ".";
    }
    $str .= " ";
  }
  my $title = $self->get_title();
  $title =~ s/^(A |An |The )//;
  $str .= $title;
  return $str;
}

# For historic reasons, we don't include any carriage
# returns-- those might be used in some cases as record separators

sub _tabrow {
  my ($self, %params) = @_;
  my $tabletop = qq!style="vertical-align:top"!;
  my $str = "<tr><td $tabletop><b>";
  my $attr = $params{attr};
  my $value = $params{value};
  my $alink = $params{alink};
  my $vlink = $params{vlink};
  my $prop  = $params{property};
  my $lprop = $params{lprop};
  if ($alink) {
    $str .= "<a href=\"$alink\">$attr</a>";
  } else {
    $str .= $attr;
  }
  $str .= ":</b></td><td $tabletop>";
  if ($prop) {
    $value = "<span itemprop=\"$prop\">$value</span>";
  }
  if ($vlink) {
    my $properties = "href=\"$vlink\"";
    if ($lprop) {
      $properties .= " itemprop=\"$lprop\"";
    }
    $value = "<a $properties>$value</a>";
  }
  $str .= "$value</td></tr>\n";
  return $str;
}

my $BLANKROW = "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>\n";

sub long_entry {
  my ($self, %params) = @_;
  my $str;
  $str .= "<div itemscope itemtype=\"http://schema.org/Book\">";
  # $str .= "<meta itemprop=\"bookFormat\" href=\"http://schema.org/EBook\" />";
  $str .= "<table>";
  my $titleattribute = ($self->{notrealtitle} ? "Name" : "Title");
  $str .= $self->_tabrow(attr=>$titleattribute, alink=>$OLBP::titlespage,
                         value=>$self->{title}, property=>"name");
  if ($self->{othertitles}) {
    foreach my $t (@{$self->{othertitles}}) {
      $str .= $self->_tabrow(attr=>"Alternate title", value=>$t);
    }
  }
  my @names = @{$self->{name}};
  my @roles = @{$self->{role}};
  my $numnames = scalar(@names);
  for (my $i = 0; $i < $numnames; $i++) {
    my $formalname = $names[$i];
    my $role = ucfirst(lc($roles[$i]));
    my $prop = "";
    if ($role =~ /Author|Editor|Illustrator/) {
      $prop = lc($role);
    }
    my $vlink = "lookupname?key=" . OLBP::url_encode($formalname);
    $str .= $self->_tabrow(alink=>$OLBP::authorspage, vlink=>$vlink,
                           attr=>$role, value=>$formalname, property=>$prop);
  }
  my $note = $self->_booknote();
  if ($note) {
    $note =~ s/^\s*\(//;
    $note =~ s/\)\s*$//;
    $str .= $self->_tabrow(attr=>"Note", value=>$note);
  }
  if ($params{workrec}) {
    my $heading = "Edition of";
    if ($self->{WREF} && ${$self->{WREF}}[0]) {
      $heading = "Version of";
    }
    $str .= $self->_tabrow(attr=>$heading,
                           value=>$params{workrec}->short_entry());
  }
  $str .= $BLANKROW;
  my @refs = @{$self->{REF}};
  foreach my $ref (@refs) {
    if ($ref =~ /(\S+)\s+(.*)/) {
       my ($l, $v) = (_ref_link_encode($1), $2);
       $str .= $self->_tabrow(attr=>"Link", vlink=>$l, value=>$v, lprop=>"url");
    }
  }
  my $slink = $self->get_stable_link();
  if ($slink && $self->curated()) { 
    $str .= $self->_tabrow(attr=>"Stable link here", value=>$slink);
    # $str .= $self->_tabrow(attr=>"Stable link here", alink=>$OLBP::stablepage,
    #                       vlink=>$slink, value=>$slink);
  } elsif ($self->get_id()) {
    my $id = $self->get_id();
    my $url = $OLBP::suggestformurl . "?id=$id";
    my $info = "This is an uncurated book entry from our extended bookshelves,";
    $info .= " readable online now but without a stable link here.";
    $info .= " You should not bookmark this page, but ";
    $info .= " you can <a href=\"$url\">request that we add this book</a>";
    $info .= " to our curated collection, which has stable links.";
    $str .= $self->_tabrow(attr=>"No stable link", value=>$info);
  }
  $str .= $BLANKROW;
  if ($self->{subject}) {
    my @subs = @{$self->{subject}};
    foreach my $sub (@subs) {
      my $sublink = "browse?type=lcsubc&amp;key="
           . OLBP::url_encode($sub) . ($self->curated() ? "" : "&amp;c=x");
      $str .= $self->_tabrow(vlink=>$sublink,
                             attr=>"Subject", value=>$sub);
    }
    if ($self->{autosubjects}) {
      my $note = $SDISCLAIMER;
      $str .= $self->_tabrow(attr=>"Subject note", value=>$note);
    }
  }
  my $lccn = $self->get_lccn();
  if ($lccn) {
    my $vlink = "browse?type=lccn&amp;key=" . OLBP::url_encode($lccn);
    if (!($self->curated())) {
      $vlink .= "&amp;c=x";
    }
    $str .= $self->_tabrow(alink=>$OLBP::calloverview, vlink=>$vlink,
                           attr=>"Call number", value=>$lccn);
  }
  my $sub = $params{titlesub};
  if ($sub) {
    $str .= $BLANKROW;
     my $sublink = "browse?type=lcsubc&amp;key=" . OLBP::url_encode($sub);
     $str .= $self->_tabrow(vlink=>$sublink, attr=>"More info",
                            value=>"Online books about this work");
  }
  if (1) {
  # if ($params{libchoice}) {
    my $info = "Look for editions of this book at ";
    # my $shorti = $self->get_short_title();
    # $shorti = search_key_for_title($shorti);
    # my $url = $OLBP::seealsourl . "?ti=" . OLBP::url_encode($shorti);
    my $url = $OLBP::seealsourl . "?ti=" . OLBP::url_encode($self->{title});
    if ($names[0]) {
      # my $akey = search_key_for_name($names[0]);
      my $akey = $names[0];
      $url .= "&amp;au=" . OLBP::url_encode($akey);
    }
    $info .= "<a href=\"$url\">your library</a>, or ";
    $info .= "<a href=\"$url\&amp;library=0CHOOSE0\">elsewhere</a>.";
    $str .= $self->_tabrow(attr=>"Other copies", value=>$info);
  }

  $str .= "</table>";
  $str .= "</div>";
  return $str;
}

sub add_wref {
  my ($self, %params) = @_;
  my $id = $params{id};
  my $heading = $params{heading};
  my $msg = $params{msg};
  return 0 if (!$id);
  if (!$params{nocheck}) {
    if ($self->{WREF}) {
      my @list = @{$self->{WREF}};
      foreach my $item (@list) {
        $item =~ s/^.*\]\s*//;
        $item =~ s/(\S)\s.*/$1/;
        # print "checking -$id- against -$item-\n";
        return 0 if ($item eq $id);
      }
    }
  }
  if ($msg && $heading) {
    $heading = $heading . "|" . $msg;
  }
  if ($heading) {
    $id = "[$heading] $id";
  }
  push @{$self->{WREF}}, $id;
  return $id;
}

# inherit prepends names and subjects
# (and possibly later on, other things)
# from the record passed in the from parameter,
# unless there are already values there and the
# addednames or addedsubs attribute is not set.

sub inherit {
  my ($self, %params) = @_;
  my $wr = $params{from};
  if ($self->{name}->[0]) {
    if ($self->{addednames}) {
      unshift @{$self->{name}}, @{$wr->{name}};
      unshift @{$self->{role}}, @{$wr->{role}};
      unshift @{$self->{wdbref}}, @{$wr->{wdbref}};
      unshift @{$self->{informalname}}, @{$wr->{informalname}};
    }
  } else {
    $self->{name} = $wr->{name};
    $self->{role} = $wr->{role};
    $self->{wdbref} = $wr->{wdbref};
    $self->{informalname} = $wr->{informalname};
  }
  if ($self->{subject}->[0]) {
    if ($self->{addedsubs}) {
      unshift @{$self->{subject}}, @{$wr->{subject}};
      unshift @{$self->{subjtype}}, @{$wr->{subjtype}};
    }
  } else {
    $self->{subject} = $wr->{subject};
    $self->{subjtype} = $wr->{subjtype};
  }
  # if we don't have an LCCN, use our parent's (but add something 
  # to the end to make us appear later in the shelf)
  if (!$self->{LCCN} && $wr->get_lccn()) {
    $self->{LCCN} = $wr->get_lccn() . "x";
  }
  # if we don't have a title of our own, use our parent's (with its status)
  if (!$self->get_title()) {
    $self->{title} = $wr->get_title();
    $self->{notrealtitle} = $wr->{notrealtitle};
  }
}

# substitute_works replaces book records with their works, if they have one,
# and the works are also in the list.
# Not an OO method

sub substitute_works {
  my @recs = @_;
  my @newlist = ();
  my %recidhash = map { $_->get_id() => $_ } @recs;
  foreach my $rec (@recs) {
    my $id = $rec->get_id();
    my $wr = $rec->get_work();
    if (!$wr || !$recidhash{$wr}) {
      if ($recidhash{$id} ne "OK") {
        push @newlist, $rec;
        $recidhash{$id} = "OK";
      }
    } else {
      $recidhash{$id} = "OK";
      while ($recidhash{$wr} && $recidhash{$wr} ne "OK") {
        my $wrec = $recidhash{$wr};
        $recidhash{$wr} = "OK";
        my $wref = $wrec->get_work();
        if (!$wref || !$recidhash{$wref}) {
           push @newlist, $wrec;
        } else {
          $wr = $wref;
        }
      }
    }
  }
  return @newlist;
}

sub short_entry {
  my ($self, %params) = @_;
  my $str;
  my $authornum = $params{useauthor};
  my @refs = @{$self->{REF}};
  my $numrefs = scalar(@refs);
  my $ref;
  my $singlerefremark;
  my $skip = -1;
  my $slink = $self->get_stable_link();
  my $icon = ($self->curated() ? $OLBP::infologo : $OLBP::xinfologo);
  my $alt = ($self->curated() ? "Info" : "X-Info");
  if ($slink) { 
    my $imageelt = "<img class=\"info\" src=\"$icon\" alt=\"\[$alt\]\" />";
    $str .= "<a href=\"$slink\">$imageelt</a> ";
  }
  if ($authornum) {
    my $which = $authornum - 1;
    my $roleabbr;
    my $name = $self->{name}->[$which];
    my $role = $self->{role}->[$which];
    if ($role) {
      $roleabbr = $ROLEABBR{$role};
    }
    $str .= $name;
    if ($roleabbr) {
      $str .= ", $roleabbr";
    }
    $str .= ": ";
  }
  if (($numrefs == 1) && $refs[0] =~ /(\S+)\s+(\S.*)/) {
    $str .= "<a href=\"" . _ref_link_encode($1). "\">";
    $singlerefremark = $2;
  }
  $str .= $self->_titlewithnote(1);
  $str .= "</a>" if ($singlerefremark);
  if (!$params{nocredits}) {
    $str .= $self->_creatorcredits(skip=>$authornum);
  }
  if ($singlerefremark) {
    $str .= " ($singlerefremark)";
  } else {
    $str .= "<ul>";
    foreach $ref (@refs) {
      if ($ref =~ /(\S+)\s+(.*)/) {
         $str .= "<li> <a href=\"" . _ref_link_encode($1) . "\">$2</a></li>";
      }
    }
    $str .= "</ul>";
  }
  return $str;
}

# We create a separate RSS entry for each item
# For simplicity, we don't do HTML 

sub rss_entries {
  my ($self, %params) = @_;
  my $titleelem;
  my $linkelem;
  my @refs = $self->get_refs();
  my $str;
  my $title = $self->get_short_title();
  $titleelem = "<title>$title";
  my @authors = $self->get_names();
  my $firstauthor = $authors[0];
  if ($firstauthor) {
    $firstauthor =~ s/[,\(\[].*//;
    $titleelem .= " ($firstauthor)";
  }
  $titleelem .= "</title>\n";
  my $slink = $self->get_stable_link();
  if ($params{consolidate} && scalar(@refs) != 1 && $slink) {
    $linkelem = "<link>" . OLBP::html_encode($slink) . "</link>";
    my $desc = $self->_titlewithnote(0);
    $desc .= $self->_creatorcredits();
    $desc .= " (stable link)";
    my $descelem = "<description>$desc</description>";
    $str .= "<item>$titleelem $linkelem $descelem</item>\n";
  }
  else {
    foreach my $ref (@refs) {
      if ($ref =~ /(\S+)\s+(.*)/) {
        my $linkcomment = $2;
        $linkelem = "<link>" . OLBP::html_encode($1) . "</link>";
        my $desc = $self->_titlewithnote(0);
        $desc .= $self->_creatorcredits();
        $desc .= " ($linkcomment)";
        my $descelem = "<description>$desc</description>";
        my $dateelem = "<pubDate>" . $self->get_rfc822_date() . "</pubDate>";
        # $descelem .= OLBP::html_encode($desc) . "</description>";
        my $telem = $titleelem;
        if ($linkcomment =~ /(([Pp]art|[Vv]olume)[^:]*):/) {
          my $volumenote = $1;
          $telem =~ s/\)</; $volumenote\)</;
        }
        $str .= "<item>$telem $linkelem $descelem</item>\n";
      }
    }
  }
  return OLBP::Entities::numeric_entities($str);
}

# We give various bonuses out to the subjects
# first subject: 80
# second subject: 50
# third subject: 20
# if publication year given,  -1920 + pubyear (min 0)
# if subject includes a year, 50 - (pubyear - subyear) (max 50, min 0)
#  though if subject includes a range it has to be within the range
# if it's a multi-edition work, +40

sub adjust_subject_scores {
  my ($self, %params) = @_;
  my $position_bonus = 80;
  my $baselineyear = 1920;
  my $pubyear = $self->_probable_publication_year();
  return undef if (!$self->{subject});
  for (my $i = 0; $i < scalar @{$self->{subject}}; $i++) {
    my $bonus = 0;
    if ($pubyear > $baselineyear && ($pubyear < $baselineyear + 150)) {
      # someone may need to adjust the line above come 2070
      $bonus += ($pubyear - $baselineyear);
    }
    my $sub = $self->{subject}->[$i];
    if (($sub =~ /(\d\d\d\d)$/) || ($sub =~ /(\d\d\d\d) --/)) {
      my $subyear = $1;
      my $startyear = 0;
      if ($sub =~ /(\d\d\d\d)-$subyear/) {  # it's an interval
        $startyear = $1;
      }
      if (($pubyear >= $startyear) && ($subyear + 50 > $pubyear)) {
        if ($pubyear < $subyear) {
          $bonus += 50;
        } else {
          $bonus += (50 - ($pubyear - $subyear));
        }
      }
    }
    if ($self->{workrec}) {
      $bonus += 40;
    }
    $bonus += $position_bonus;
    $position_bonus -= 30;
    $position_bonus = 0 if ($position_bonus < 0);
    # if ($sub =~ /algebra, abstract/i) {
    #   print $self->{ID} . "sub: $sub; year: $pubyear; bonus $bonus\n";
    # }
    if ($bonus > 0) {
      $self->{subjscore}->[$i] += $bonus;
    }
  }
}

sub _readin {
  my ($self, %params) = @_;
  my $str = $params{string};
  my @lines = split /\n/, $str;
  foreach my $line (@lines) {
    if ($line =~ /^REF\s+(.*\S)/) {
      push @{$self->{REF}}, $1;
      if ($1 =~ / .*serial archives/) {
        $self->{serial} = 1;
      }
      if ($1 =~ / .*multiple editions/) {
        $self->{workrec} = 1;
      }
    } elsif ($line =~ /^(SREF|SOSC|SREL|NUREF|SERIES|WBIB|WPART|WREF|WREL)\s+(.*\S)/) {
      push @{$self->{$1}}, $2;
    } elsif ($line =~ /^(LC[A-Z]*SUB)\+?(,[0-9\.\-]*)?\s+(.*\S)/) {
      my $which = $1;
      my $score = $2;
      my $what = $3;
      if (!($what =~ /^\[(implied|suppressed)\]/)) {
        push @{$self->{subjtype}}, $which;
        push @{$self->{subject}}, $what;
        $score ||= 0;
        push @{$self->{subjscore}}, $score;
      }
      if ($line =~ /^[A-Z]+\+/) {
        $self->{addedsubs} = 1;
      }
    } elsif ($line =~ /^(SDESC|SHIST|NOTE|LCCN|ID|WDESC|EDOF|PARTOF|TSUB)\s+(.*\S)/) {
      if ($self->{$1}) {
        return _formaterror("$1 already assigned");
      }
      $self->{$1} =  $2;
    } elsif ($line =~
               /^(AUTHOR|EDITOR|TRANSLATOR|ILLUSTRATOR|CONTRIBUTOR)\+?\s+(.*\S)/) {
      push @{$self->{role}}, $1;
      my $who = $2;
      my $wdbref = "";
      if ($line =~ /^[A-Z]+\+/) {
        $self->{addednames} = 1;
      }
      if ($who =~ /^\[(\w*)]\s+(.*\S)/) {
        ($wdbref, $who) = ($1, $2);
      }
      my $informalname = $who;
      if ($who =~ /(.*\S)\s*\|\*\s*(.*)/) {
        # A |* indicates a substitute name for informal names follows
        # (|* by itself means informal and formal names are identical)
        # If informal name radically different, best to put a cross-ref in DB
        ($who, $informalname) = ($1, $2);
        if (!$informalname) {
          $informalname = $who;
        }
      } else {
        $informalname = _informalname($who);
      }
      if ($wdbref) {
        push @{$self->{wdbref}}, $wdbref;
      }
      push @{$self->{name}}, $who;
      push @{$self->{informalname}}, $informalname;
    } elsif ($line =~ /^(NAME|TITLE)\s+(.*\S)/) {
      if ($self->{title}) {
        return _formaterror("NAME or TITLE already assigned");
      }
      $self->{title} = $2;
      if ($1 =~ /NAME/) {
        $self->{notrealtitle} = 1;
      }
    } elsif ($line =~ /^ATITLE\s+(.*\S)/) {
      push @{$self->{othertitles}}, $1;
    } elsif ($line =~ /^SET\s+(.*\S)/) {
      push @{$self->{sets}}, (split / /, $1);
    } elsif ($line =~ /^DATE\s+(.*\S)/) {
      if ($self->{date}) {
        return _formaterror("DATE already assigned");
      }
      my $dstr = _isodate($1);
      if (length($dstr) != 10) {
        return _formaterror("DATE badly formatted");
      }
      $self->{date} = $dstr;
    }
  }
  $OLBP::BookRecord::error = "";
  return $self;
}

sub unparse {
  my ($self, %params) = @_;
  my $str;
  my @refs = $self->get_refs();
  foreach my $ref (@refs) {
    $str .= "REF $ref\n";
  }
  my @names = @{$self->{name}};
  my @roles = @{$self->{role}};
  my $field;
  my $numnames = scalar(@names);
  if ($numnames) {
    for (my $i = 0; $i < $numnames; $i++) {
      my $wdbbit = $self->{wdbref}->[$i];
      if ($wdbbit) {
        $wdbbit = "[$wdbbit] ";
      }
      my $informalbit = $self->{informalname}->[$i];
      if ($informalbit ne _informalname($names[$i])) {
        if ($informalbit eq ($names[$i])) {
          $informalbit = "|*";
        } else {
          $informalbit = "|* $informalbit";
        }
      } else {
        $informalbit = "";
      }
      $str .= "$roles[$i] " . $wdbbit  . $names[$i] . $informalbit . "\n";
    }
  }
  if ($self->{title}) {
    $str .= ($self->{notrealtitle} ? "NAME" : "TITLE");
    $str .= " $self->{title}\n";
  }
  if ($self->{othertitles}) {
    foreach my $t (@{$self->{othertitles}}) {
      $str .= "ATITLE $t\n";
    }
  }
  foreach $field ("NOTE", "LCCN", "SDESC", "SHIST",
                  "WDESC", "EDOF", "PARTOF", "TSUB") {
    if ($self->{$field}) {
      $str .= "$field $self->{$field}\n";
    }
  }
  if ($self->{subject}) {
    my $prefix = "";
    if ($self->{autosubjects}) {
      $prefix = "[implied] ";
    }
    for (my $i = 0; $self->{subject}->[$i]; $i++) {
      my $which = $self->{subjtype}->[$i];
      my $value = $self->{subject}->[$i];
      $str .= "$which $prefix$value\n";
    }
  }
  foreach $field ("SREF", "SOSC", "SREL", "NUREF", "SERIES",
                  "WBIB", "WPART", "WREF", "WREL") {
    if ($self->{$field}) {
      foreach my $value (@{$self->{$field}}) {
        $str .= "$field $value\n";
      }
    }
  }
  if ($self->{sets} && scalar(@{$self->{sets}})) {
    $str .= "SET " . (join ' ', @{$self->{sets}}) . "\n";
  }
  if ($self->{date} =~ /(\d+)-(\d+)-(\d+)/) {
    $str .= "DATE " . int($3) . " $month[$2-1] $1\n";
  }
  $str .= "ID " . $self->get_id() . "\n\n";
  return $str;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{name} = [];
  $self->{wdbref} = [];
  $self->{informalname} = [];
  $self->{role} = [];
  $self->{othertitles} = [];
  $self->{sets} = [];
  $self->{REF} = [];
  $self->{NUREF} = [];
  $self->{subject} = [];
  $self->{subjtype} = [];
  $self->{subjscore} = [];
  if ($params{string}) {
    if (!$self->_readin(%params)) {
      return 0;
    }
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

