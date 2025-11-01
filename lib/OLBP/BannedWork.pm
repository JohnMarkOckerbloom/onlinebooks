package OLBP::BannedWork;
use strict;
use JSON;
use OLBP;
# use Locale::Country;

my $citedir  = $OLBP::dbdir . "banned/bib/";

my @month = ("January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December");

my $serverurl    = "https://onlinebooks.library.upenn.edu/";
my $imageprefix  = $serverurl . "covers/";
my $cgiprefix    = $serverurl . "webbin/";
my $bannedscript = $cgiprefix . "banned";

my $wpprefix     = "https://en.wikipedia.org/wiki/";
my $ltworkprefix = "https://www.librarything.com/work/";
my $grworkprefix = "https://www.goodreads.com/book/show/";

my $bookshopprefix   = "https://bookshop.org/books?";
my $amazonprefix     = "https://www.amazon.com/s?";
my $bnprefix         = "https://www.barnesandnoble.com/s/";
my $bookfinderprefix = "https://www.bookfinder.com/search/?mode=basic&st=sr&ac=qr&lang=any&";

my $countries = {
  'AU' => "Australia", 'AT' => "Austria",
  'CA' => "Canada", 'CN' => "China", 'CU' => "Cuba", 'FR' => "France",
  'DE' => "Germany", 'GR' => "Greece", 'IR' => "Iran",
  'MY' => "Malaysia",  'MM' => "Myanmar",
  'NO' => "Norway", 'SA' => "Saudi Arabia", 'SG' => "Singapore",
  'ES' => "Spain", 'ZA' => "South Africa", 'SU' => "Soviet Union",
  'TR' => "Turkey", 'UK' => "United Kingdom", 'US' => "United States"
};

my $states = {
  'AL' => "Alabama", 'AK' => "Alaska", 'AZ' => "Arizona", 'AR' => "Arkansas",
  'CA' => "California", 'CO' => "Colorado", 'CT' => "Connecticut",
  'DE' => "Delaware", 'DC' => "District of Columbia", 'FL' => "Florida",
  'GA' => "Georgia", 'HI' => "Hawaii", 'IA' => "Iowa",
  'ID' => "Idaho", 'IL' => "Illinois", 'IN' => "Indiana",
  'KS' => "Kansas", 'KY' => "Kentucky", 'LA' => "Louisiana",
  'MD' => "Maryland", 'MA' => "Massachusetts", 'ME' => "Maine",
  'MI' => "Michigan", 'MS' => "Mississippi", 'MN' => "Minnesota",
  'MO' => "Missouri", 'MT' => "Montana",
  'NE' => "Nebraska", 'NV' => "Nevada", 'NH' => "New Hampshire",
  'NJ' => "New Jersey", 'NM' => "New Mexico",
  'NY' => "New York",
  'NC' => "North Carolina", 'ND' => "North Dakota",
  'OH' => "Ohio", 'OK' => "Oklahoma", 'OR' => "Oregon",
  'PA' => "Pennsylvania", 'PR' => "Puerto Rico", 'RI' => "Rhode Island",
  'SC' => "South Carolina", 'SD' => "South Dakota",
  'TN' => "Tennessee", 'TX' => "Texas", 'UT' => "Utah",
  'VA' => "Virginia", 'VI' => "Virgin Islands", 'VT' => "Vermont",
  'WA' => "Washington", "WV" => "West Virginia",
  "WI" => "Wisconsin", 'WY' => "Wyoming"
};

my $provinces = {"AB" => "Alberta", "BC" => "British Columbia",
                 "MB" => "Manitoba", "NB" => "New Brunswick",
                 "NL" => "Newfoundland and Labrador",
                 "NT" => "Northwest Territories", "NS" => "Nova Scotia",
                 "NU" => "Nunavut", "ON" => "Ontario",
                 "PE" => "Prince Edward Island",
                 "PQ" => "Qu&eacute;bec", "SK" => "Saskatchewan",
                 "YT" => "Yukon"
};

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

sub get_id { return shift->{id}};
sub get_title { return shift->{title}};

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

# For now, a simple expansion of US; more coming later

sub _location_string {
  my ($location) = @_;
  my $str = "";
  my $loccode = "";
  if (ref($location)) { 
    if ($location->{"name"}) {
      return $location->{"name"};
    }
    $loccode = $location->{"code"};
  } else {
    $loccode = $location;
  }
  $str = $loccode;
  if ($loccode =~ /^US-([A-Z][A-Z])(-.*)?/) {
    my ($statecode, $locality) = ($1, $2);
    $str = $states->{$statecode};
    if ($2) {
      $str = "$locality, $str";
    }
  } elsif ($loccode =~ /^CA-([A-Z][A-Z])(-.*)?/) {
    my ($provcode, $locality) = ($1, $2);
    $str = $provinces->{$provcode};
    if ($2) {
      $str = "$locality, $str";
    }
  } elsif ($countries->{$loccode}) {
    $str = $countries->{$loccode};
  }
  return $str;
}

# Right now we're only returning the authorized form of an author or editor
# but we'll get more robust as we need to

sub _first_author {
  my ($self) = @_;
  my $json = $self->{json};
  my $author = $json->{"author"};
  if (!$author && $json->{"authors"}) {
    $author = $json->{"authors"}->[0];
  }
  if (!$author) {
    $author = $json->{"editor"};
  }
  if (!$author && $json->{"editors"}) {
    $author = $json->{"editors"}->[0];
  }
  if ($author) {
    return $author->{"authorized"};
  };
  return "";
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
  return $str;
}

sub _show_plural_names {
  my ($self, $arrayref) = @_;
  return "" if (!$arrayref);
  my @names = map {$self->_display_person($_)} @{$arrayref};
  my $str = join ', ', @names;
  return $str;
}

sub _basic_info_html {
  my ($self, %params) = @_;
  my $json = $self->{json};
  my $title = $self->{title};
  my $str = "<table>";
  $str .= $self->_tabrow(attr=>"Title",
                       value=>"<cite>" . OLBP::html_encode($title) .
                              "</cite>");
  if ($json->{"author"}) {
    my $authorstr .= $self->_display_person($json->{"author"});
    $str .= $self->_tabrow(attr=>"Author", value=>$authorstr);
  } elsif ($json->{"authors"}) {
    my $authorstr .= $self->_show_plural_names($json->{"authors"});
    $str .= $self->_tabrow(attr=>"Authors", value=>$authorstr);
  }
  if ($json->{"editor"}) {
    my $authorstr .= $self->_display_person($json->{"editor"});
    $str .= $self->_tabrow(attr=>"Editor", value=>$authorstr);
  } elsif ($json->{"editors"}) {
    my $authorstr .= $self->_show_plural_names($json->{"editors"});
    $str .= $self->_tabrow(attr=>"Editors", value=>$authorstr);
  };
  if ($json->{"illustrator"}) {
    my $authorstr .= $self->_display_person($json->{"illustrator"});
    $str .= $self->_tabrow(attr=>"Illustrator", value=>$authorstr);
  } elsif ($json->{"illustrators"}) {
    my $authorstr .= $self->_show_plural_names($json->{"illustrators"});
    $str .= $self->_tabrow(attr=>"Illustrators", value=>$authorstr);
  };
  my $firstpub = $json->{"first-published"};
  my $pubstr = "";
  if (ref($firstpub)) {
    my $date = $firstpub->{"date"};
    $pubstr = _date_string($date);
    my $note = $firstpub->{"note"};
    if ($note) {
      $pubstr .= " ($note)";
    }
  } else {
    $pubstr = _date_string($firstpub);
  }
  if ($pubstr) {
    $str .= $self->_tabrow(attr=>"First published", value=>$pubstr);
  };
  $str .= "</table>";
  return $str;
}

sub _online_access_html {
  my ($self, %params) = @_;
  my $json = $self->{json};
  my $id = $self->{id};
  my $url = "";
  if ($json->{"online-work"}) {
    $url = $cgiprefix . "work?id=$id";
  } elsif ($json->{online}) {
    $url = $cgiprefix . "book/lookupid?key=$id";
  }
  if ($url) {
   return qq!<strong><a href="$url">via The Online Books Page</a></strong>!;
  }
  return undef;
} 

sub _about_link_html {
  my ($id, $prefix, $name) = @_;
  if ($id) {
    my $url = $prefix . $id;
    return qq!<a href="$url">$name</a>!;
  }
  return "";
}

sub _about_html {
  my ($self, %params) = @_;
  my @aboutlinks = ();
  my $json = $self->{json};
  my $qid = $json->{wikidata};
  my $wdhash = $self->{wdhash};
  if ($wdhash && $qid) {
    my $article = $wdhash->get_value(key=>$qid);
    $article ||= $json->{wikipedia};
    if ($article) {
      push @aboutlinks, _about_link_html($article, $wpprefix, "Wikipedia");
    } 
  }
  my $ltid = $json->{librarything};
  if ($ltid) {
    push @aboutlinks, _about_link_html($ltid, $ltworkprefix, "LibraryThing");
  }
  my $grid = $json->{goodreads};
  if ($grid) {
    push @aboutlinks, _about_link_html($grid, $grworkprefix, "GoodReads");
  }
  if (scalar(@aboutlinks)) {
    return join ' | ', @aboutlinks;
  }
  return undef;
} 

sub _borrow_link_html {
  my ($query, $name, $libraryid) = @_;
  my $url = $OLBP::seealsourl . "?$query";
  if ($libraryid) {
    $url .= "&amp;library=$libraryid";
  }
  return qq!<a href="$url">$name</a>!;
}

sub _bookshop_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "keywords=$title";
  $query .= " by $informalauthor" if ($informalauthor);
  $query =~ s/\s+/\+/g;
  my $url = "$bookshopprefix$query";
  return qq!<a href="$url">Bookshop.org</a>!;
}

sub _amazon_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "k=$title";
  $query .= " by $informalauthor" if ($informalauthor);
  $query =~ s/\s+/\+/g;
  my $url = "$amazonprefix$query";
  return qq!<a href="$url">Amazon</a>!;
}

sub _bn_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "keywords=$title";
  $query .= " by $informalauthor" if ($informalauthor);
  $query =~ s/\s+/\+/g;
  my $url = "$bnprefix$query";
  return qq!<a href="$url">Barnes &amp; Noble</a>!;
}

sub _bookfinder_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "author=$informalauthor&title=$title";
  $query =~ s/\s+/\+/g;
  my $url = "$bookfinderprefix$query";
  return qq!<a href="$url">Bookfinder.com</a>!;
}

sub _borrow_html {
  my ($self, %params) = @_;
  my @borrowlinks = ();
  my $title = $self->{title};
  my $ftlquery = "ti=" . OLBP::url_encode($title);
  my $author = $self->_first_author();
  if ($author) {
    $ftlquery .= "&amp;au=" . OLBP::url_encode($author);
  }
  push @borrowlinks, _borrow_link_html($ftlquery, "Your library");
  push @borrowlinks,
   _borrow_link_html($ftlquery, "Another library", "0CHOOSE0");
  push @borrowlinks,
   _borrow_link_html($ftlquery, "Find a library with it (via WorldCat)", "OCLC-WCDGL");
  if (scalar(@borrowlinks)) {
    return join ' | ', @borrowlinks;
  }
  return "";
} 

sub _buy_html {
  my ($self, %params) = @_;
  my @buylinks = ();
  my $title = $self->{title};
  my $author = $self->_first_author();
  push @buylinks, _bookshop_buy_link_html($title, $author);
  push @buylinks, _amazon_buy_link_html($title, $author);
  push @buylinks, _bn_buy_link_html($title, $author);
  push @buylinks, _bookfinder_buy_link_html($title, $author);
  if (scalar(@buylinks)) {
    return join ' | ', @buylinks;
  }
  return "";
} 

sub _book_access_html {
  my ($self, %params) = @_;
  my $json = $self->{json};
  my $str = "<table>";
  my $value = $self->_online_access_html();
  if ($value) {
    $str .= $self->_tabrow(attr=>"Read it online", value=>$value);
  }
  $value = $self->_about_html();
  if ($value) {
    $str .= $self->_tabrow(attr=>"Read about it at", value=>$value);
  }
  $value = $self->_borrow_html();
  if ($value) {
    $str .= $self->_tabrow(attr=>"Borrow it from", value=>$value);
  }
  $value = $self->_buy_html();
  if ($value) {
    $str .= $self->_tabrow(attr=>"Buy it from", value=>$value);
  }
  $str .= "</table>";
  return $str;
}

sub cover_display_html {
  my ($self, %params) = @_;
  my $str = "";
  my $json = $self->{json};
  return "" if (!$json);
  my $cover = $json->{cover};
  return "" if (!$cover);
  my $filename = $cover->{file};
  my $alt = $cover->{alt};
  my $url = $imageprefix . $filename;
  my $linkurl = "";
  my $frameclassstr = "cover-frame";
  $frameclassstr .= " cover-on-page" if (!$params{brief});
  $str = qq!<div class="$frameclassstr">!;
  $str .= qq!<div class="cover-image">!;
  if ($params{link}) {
    my $id = $self->{id};
    $linkurl = "$bannedscript/work/$id";
    $str .= qq!<a href="$linkurl">!;
  }
  $str .= qq!<img src="$url" alt="$alt">!;
  if ($params{link}) {
    $str .= qq!</a>!;
  }
  $str .= "</div>";
  $str .= qq!<div class="cover-text">!;
  if ($params{brief}) {
    my $title = $self->get_title();
    my $titlestr = "<cite>$title</cite>";
    if ($linkurl) {
      $titlestr = qq!<a href="$linkurl">$titlestr</a>!;
    }
    $str .= qq!$titlestr!;
    my $authorstr = $self->get_author_summary();
    if ($authorstr) {
      $str .= qq!<br>by $authorstr!;
    }
  }
  else {
    my $desc = $cover->{description};
    my $source = $cover->{source};
    my $sourceurl = $cover->{url};
    if ($desc) {
      $str .= qq!$desc (Source: <a href="$sourceurl">$source</a>)!;
    } else {
      $str .= qq!Source: <a href="$sourceurl">$source</a>!;
    }
  }
  $str .= "</div></div>";
  return $str;
}

sub _incident_html {
  my ($incident) = @_;
  my $str = "";
  my $heading = "";
  my $description = $incident->{description};
  if ($incident->{date}) {
    $heading = _date_string($incident->{date});
    if ($incident->{location}) {
      $heading .= ' (' . _location_string($incident->{location}) . ')';
    }
  }
  if ($heading) {
    $str = "<strong>$heading:</strong> ";
  }
  $str .= OLBP::BannedUtils::expand_html_template($description);
  my $citeref = $incident->{citation};
  if ($citeref) {
    my $source = $citeref->{source};
    my $pages = $citeref->{pages};
    if ($source) {
      my $citation = new OLBP::BannedCitation(dir=>$citedir, id=>$source,
                                              pages=>$pages);
      $str .= " <em>(" . $citation->display_html() . ")</em>";
    }
  }
  return $str;
}


sub _documentation_display_html {
  my ($self, %params) = @_;
  my $str = "";
  my $json = $self->{json};
  return "" if (!$json);
  $str = qq!<div class="documentation">!;
  if ($json->{overview}) {
    $str .= qq!<div class="overview">!;
    $str .= OLBP::BannedUtils::expand_html_template($json->{overview});
    $str .= qq!</div>!;
  }
  if ($json->{incidents}) {
    $str .= qq!<div class="incidents">!;
    $str .= qq!<ul>!;
    foreach my $incident (@{$json->{incidents}}) {
      $str .= "<li> " . _incident_html($incident);
    }
    $str .= qq!</ul>!;
    $str .= qq!</div>!;
  }
  $str .= qq!</div>\n!;
  return $str;
}

sub _category_display_html {
  my ($self, %params) = @_;
  my $str = "";
  my @cats = $self->get_categories(implicit=>1);
  my @links = ();
  if (scalar(@cats) > 1) {
    foreach my $cat (sort @cats) {
      next if ($cat eq "all");
      my $url = "$bannedscript/category/$cat";
      push @links, qq!<a href="$url">$cat</a>!;
    }
    $str = "<p><strong>Categories:</strong> " . join(' | ', @links) . "</p>\n";
  }
  return $str;
}

sub display_html {
  my ($self, %params) = @_;
  my $str = "";
  $str .= "<div>";
  $str .= $self->cover_display_html();
  $str .= $self->_basic_info_html();
  $str .= "</div>";
  $str .= "<br>";
  $str .= $self->_book_access_html();
  $str .= "<hr>\n";
  $str .= $self->_documentation_display_html();
  $str .= $self->_category_display_html();
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
  } elsif ($date =~ /^\d+\s+BC/) {
    return $date;
  } elsif ($date =~ /^\d+\w+ century/) {
    return $date;
  }
  return 0;
}

# returns a quick author/editor/etc. credit for a summary line
# just doing a quick summary for now

sub get_author_summary {
  my ($self, %params) = @_;
  my $json = $self->{json};
  return "" if (!$json);
  if ($json->{"author"}) {
    return $self->_display_person($json->{"author"});
  }
  if ($json->{"authors"}) {
    return $self->_display_person($json->{"authors"}->[0]) . " et al.";
  }
  if ($json->{"editor"}) {
    return $self->_display_person($json->{"editor"}) . " (ed.)";
  }
  return "";
}

sub get_recent_censorship_year {
  my ($self, %params) = @_;
  my $json = $self->{json};
  my $latest = 0;
  return 0 if (!$json);
  my $incidents = $json->{"incidents"};
  foreach my $incident (@{$incidents}) {
    my $date = $incident->{date};
    if ($date =~ /^(\d\d\d\d)/) {
      my $year = $1;
      if (!$latest || ($year > $latest)) {
        $latest = $year;
      }
    }
  }
  return $latest;
}

sub is_readable_online {
  my ($self, %params) = @_;
  my $json = $self->{json};
  return 0 if (!$json);
  return 1 if ($json->{"online"} || $json->{"online-work"});
  return 0;
}

sub get_categories {
  my ($self, %params) = @_;
  my $json = $self->{json};
  my @categories = ();
  if ($json && $json->{categories}) { 
    @categories = @{$json->{categories}};
  }
  if ($params{implicit}) {
    push @categories, "all";
    if ($self->is_readable_online()) {
      push @categories, "online";
    }
    my $year = $self->get_recent_censorship_year();
    if ($year && $year > 2010) {
      push @categories, "recent-censorship";
    }
  }
  return @categories;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{id} = $params{id};
  $self->{wdhash} = $params{wdhash};
  $self->{parser} = OLBP::BannedUtils::get_json_parser();
  if ($self->{id}) {
    $self->{json} = $self->get_json(filename=>$self->{id});
  }
  if ($self->{json}) {
    $self->{title} = $self->{json}->{title};
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

