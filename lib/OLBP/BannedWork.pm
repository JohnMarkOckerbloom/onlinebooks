package OLBP::BannedWork;
use strict;
use JSON;
use OLBP;

my @month = ("January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December");

my $serverurl   = "https://onlinebooks.library.upenn.edu/";
my $imageprefix = $serverurl . "covers/";
my $cgiprefix   = $serverurl . "webbin/";

my $wpprefix     = "https://en.wikipedia.org/wiki/";
my $ltworkprefix = "https://www.librarything.com/work/";
my $grworkprefix = "https://www.goodreads.com/book/show/";

my $bookshopprefix   = "https://bookshop.org/books?";
my $amazonprefix     = "https://www.amazon.com/s?";
my $bnprefix         = "https://www.barnesandnoble.com/s/";
my $bookfinderprefix = "https://www.bookfinder.com/search/?mode=basic&st=sr&ac=qr&lang=any&";

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

sub get_title {
  my ($self, %params) = @_;
  return $self->{title};
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
    $loccode = $location->{"code"};
  } else {
    $loccode = $location;
  }
  $str = $loccode;
  if ($loccode eq "US") {
    $str = "United States";
  } elsif ($loccode eq "IR") {
    $str = "Iran";
  }
  return $str;
}

# Right now we're only returning the authorized form of a unique author
# but we'll get more robust as we need to

sub _first_author {
  my ($self) = @_;
  my $json = $self->{json};
  my $author = $json->{"author"};
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
  my $query = "keywords=$title by $informalauthor";
  $query =~ s/\s+/\+/g;
  my $url = "$bookshopprefix$query";
  return qq!<a href="$url">Bookshop.org</a>!;
}

sub _amazon_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "k=$title by $informalauthor";
  $query =~ s/\s+/\+/g;
  my $url = "$amazonprefix$query";
  return qq!<a href="$url">Amazon</a>!;
}

sub _bn_buy_link_html {
  my ($title, $author) = @_;
  my $informalauthor = _informalname($author);
  my $query = "keywords=$title by $informalauthor";
  $query =~ s/\s+/\+/g;
  my $url = "$bnprefix$query";
  return qq!<a href="$url">Barnes &amp; Noble</a>!;
}

sub _bookfinder_buy_link_html {
  my ($title, $author) = @_;
  my $query = "author=$author&title=$title";
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

sub _cover_display_html {
  my ($self, %params) = @_;
  my $str = "";
  my $json = $self->{json};
  return "" if (!$json);
  my $cover = $json->{cover};
  return "" if (!$cover);
  my $filename = $cover->{file};
  my $alt = $cover->{alt};
  my $url = $imageprefix . $filename;
  $str = qq!<div class="cover-frame">!;
  $str .= qq!<div class="cover-image">!;
  $str .= qq!<img src="$url" alt="$alt">!;
  $str .= "</div>";
  $str .= qq!<div class="cover-text">!;
  my $desc = $cover->{description};
  my $source = $cover->{source};
  my $sourceurl = $cover->{url};
  if ($desc) {
    $str .= qq!$desc (Source: <a href="$sourceurl">$source</a>)!;
  } else {
    $str .= qq!Source: <a href="$sourceurl">$source</a>!;
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
    $str = "<strong>$heading:</strong> $description";
  } else {
    $str = $description;
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
    $str = $json->{overview};
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

sub display_html {
  my ($self, %params) = @_;
  my $str = "";
  $str .= "<div>";
  $str .= $self->_cover_display_html();
  $str .= $self->_basic_info_html();
  $str .= "</div>";
  $str .= "<br>";
  $str .= $self->_book_access_html();
  $str .= "<hr>\n";
  $str .= $self->_documentation_display_html();
  return $str;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{id} = $params{id};
  $self->{wdhash} = $params{wdhash};
  $self->{parser} = JSON->new->allow_nonref;
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

