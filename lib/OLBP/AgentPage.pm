package OLBP::AgentPage;
use OLBP::Name;
use OLBP::RecordStore;
use JSON;

$OLBP::AgentPage::styleurl = $OLBP::serverurl . "whopage.css";

my $extradir  = $OLBP::dbdir . "exindexes/";
my $picpath   = "/websites/OnlineBooks/books/wdpics/";
my $imagestub = $OLBP::serverurl . "wdpics/";
my $commonsstub = "https://commons.wikimedia.org/wiki/File:";

sub _display_image {
  my ($imageref, $alttext, $sourcepage) = @_;
  print qq!<a href="$sourcepage"><img height="128" alt="$alttext" src="$imageref"></a>!;
  print qq!<br>Image from <a href="$sourcepage">Wikimedia Commons</a>!;
}

my $hashes = {};

sub gethashval {
  my ($name, $key, $dir) = @_;

  return undef if (!$name);
  my $hashid = $name;
  if ($dir) {
    $hashid .= "-$dir";
  }
  my $hash = $hashes->{$hashid};
  if (!$hash) {
    my $fname = OLBP::hashfilename($name, $dir);
    $hash = new OLBP::Hash(name=>$hashid, filename=>$fname, cache=>1);
    return undef if (!$hash);
    $hashes->{$hashid} = $hash;
  }
  return $hash->get_value(key=>$key);
}

sub get_image_info {
  my ($self) = @_;
  my $info = {};
  my $jsonstr = $self->_get_string_from_file("picmetadata.json");
  return undef if (!$jsonstr);
  my $json = $self->{parser}->decode($jsonstr);
  return undef if (!$json);
  my $query = $json->{"query"};
  return undef if (!$query);
  my $pages = $query->{"pages"};
  return undef if (!$pages);
  my @valarray = values %{$pages};
  my $page = $valarray[0];
  return undef if (!$page);
  my $title = $page->{"title"};
  $title =~ s/^File://;
  $info->{title} = $title;
  my $imageinfo = $page->{imageinfo};
  return $info if (!$imageinfo);
  my $index = $imageinfo->[0];
  my $extmetadata = $index->{"extmetadata"};
  return $info if (!$extmetadata);
  my $desc = $extmetadata->{"ImageDescription"};
  return $info if (!$desc);
  $desc = $desc->{"value"};
  $info->{desc} = $desc;
  return $info;
}

sub _display_banner {
  my ($self, $name, $informal) = @_;
  print qq!<div class="whobanner">!;
  print qq!<table><tr><td>!;
  print "<h2>$informal</h2>\n";
  my $naivename = OLBP::Name::naive($name);
  if ($naivename ne $informal) {
    print "<h3>($name)</h3>\n";
  }
  my $info = $self->get_image_info();
  if ($info) {
    print qq!</td><td width="15%"></td><td>!;
    my $desc = $info->{desc};
    my $title = $info->{title};
    $desc =~ s/\<[^\>]+\>//g;                  # strip out HTML markup
    my $picfile = $self->picfilename();
    my $picdir = $self->{stubdir};
    # print "<b>desc is $desc, title is $title, picdir is $picdir, picfile is $picfile</b>\n";
    if ($picfile && $picdir) {
      my $imageurl = "$imagestub$picdir/$picfile";
      my $commonsurl = $commonsstub . $title;
      _display_image($imageurl, $desc, $commonsurl);
    }
  }
  print qq!</td></tr></table>!;
  print "</div>";
}

sub _get_string_from_file {
  my ($self, $name, $singleline) = @_;
  my $str;
  my $path = $self->{dir} . "/$name";
  open my $fh, "< $path" or return undef;
  binmode $fh, ":utf8";
  if ($singleline) {
    $str = <$fh>;
    chomp $str;
  } else {
    my @lines = <$fh>;
    $str = join '\n', @lines;
  }
  close $fh;
  return $str;
}

sub get_heading {
  my ($self) = @_;
  if (!$self->{heading}) {
    $self->{heading} = $self->_get_string_from_file("name", 1);
  }
  if (!$self->{heading} && $self->{authornote}) {
    # No who directory, but we can pull name from note
    $self->{heading} = $self->{authornote}->get_formal_name();
  }
  return $self->{heading};
}

sub get_informal {
  my ($self) = @_;
  if (!$self->{informal}) {
    $self->{informal} = $self->_get_string_from_file("informal", 1);
  }
  if (!$self->{informal} && $self->{authornote}) {
    # No who directory, but we can pull name from note
    $self->{informal} = $self->{authornote}->get_informal_name();
  }
  return $self->{informal};
}

sub get_wikipedia_url {
  my ($self) = @_;
  if (!$self->{wpid}) {
    $self->{wpid} = $self->_get_string_from_file("wpid", 1);
  }
  return undef if (!$self->{wpid});
  return $OLBP::wpstub . $self->{wpid};
}

sub get_links {
  my ($self) = @_;
  if (!$self->{links}) {
    my $str = $self->_get_string_from_file("links.json");
    return undef if (!$str);
    my $json = $self->{parser}->decode($str);
    if ($json) {
      $self->{links} = $json;
    }
  }
  return $self->{links};
}

sub get_relationships {
  my ($self) = @_;
  if (!$self->{rels}) {
    my $str = $self->_get_string_from_file("rels.json");
    return undef if (!$str);
    my $json = $self->{parser}->decode($str);
    if ($json) {
      $self->{rels} = $json;
    }
  }
  return $self->{rels};
}

sub get_roles {
  my ($self) = @_;
  my $rels = $self->get_relationships();
  my @roles = ();
  if ($rels) {
    foreach my $rel (@{$rels}) {
      if ($rel->{type} eq "Role") {
        push @roles, $rel;
      } 
    }
  }
  if (scalar(@roles)) {
    return \@roles;
  }
  return undef;
}

sub _print_role {
  my ($self, $role) = @_;
  if ($role->{description} eq "Ambassador") {
    print $self->_livelink($role->{objectname}) . " ";
    print $role->{description};
    print " to ";
    print $self->_livelink($role->{object2name});
  } else {
    print ($role->{description});
    if ($role->{objectname}) {
      print ", " . $self->_livelink($role->{objectname});
    }
  }
  if ($role->{date1} || $role->{date2}) {
    if (!$role->{date2} || ($role->{date1} eq $role->{date2})) {
      print " ($role->{date1})";
    } else {
      print " ($role->{date1}\-$role->{date2})";
    }
  }
}

sub _print_roles {
  my ($self, @roles) = @_;
  print "\n<b>Selected roles:</b><ul>\n";
  foreach my $role (sort {$a->{start} <=> $b->{start} } @roles) {
    print "<li> ";
    $self->_print_role($role);
  }
  print "</ul>\n";
}

sub _print_additional_refs {
  my ($self, $name, $includewp) = @_;
  my @refs;
  my $links = $self->get_links();
  if ($links) {
    @refs = @{$links};
  }
  if ($includewp) {
    my $wpurl = $self->get_wikipedia_url();
    if ($wpurl)  {
      my $ref = {"note"=>"Wikipedia article", "url"=>$wpurl};
      push @refs, $ref;
    }
  }
  print "<b>More resources on this subject:</b><ul>\n";
  foreach my $ref (@refs) {
    print "<li> <a href=\"$ref->{url}\">$ref->{note}</a>";
  }
  my $url = $OLBP::seealsourl . "?su=" . OLBP::url_encode($name);
  print "<li> <a href=\"$url\">Search in your library</a>";
  $url .= "\&amp;library=0CHOOSE0";
  print "<li> <a href=\"$url\">Search in another library</a>";
  print "</ul>";
}

sub _print_lead {
  my ($self, $str) = @_;
  my $wpurl = $self->get_wikipedia_url();
  $str =~ s!\'\'\'(.*)?\'\'\'!<b>$1</b>!g;
  $str =~ s!</b>\s*\(.*?\)!</b>!;         # remove parenthetical after boldname
  print "<p>$str ";
  print qq!<em>(From <a href="$wpurl">Wikipedia</a>)</em></p>!;
}

sub showauthorhits {
  my ($store, @refs) = @_;
  return if (!scalar(@refs));
  print "<ul class=\"nodot\">";
  foreach my $ref (@refs) {
    if ($ref =~ /(.*):(\d+)/) {
      my ($bookid, $position) = ($1, $2);
      my $br = $store->get_record(id=>$bookid);
      if ($br) {
        print "<li>" . $br->short_entry(useauthor=>$position) . "</li>";
      }
    }
  }
  print "</ul>";
}

# We don't yet display author note here- might want to in future?
sub display_works {
  my ($self, %params) = @_;
  my $val = $params{curatedbookvals};
  my $exval = $params{extendedbookvals};
  my $store = new OLBP::RecordStore(dir=>$OLBP::dbdir);
  if ($val || $exval) {
    # do we want to add an author note here?  Or elsewhere?
    showauthorhits($store, (split '\s+', $val));
    if ($exval) {
      print ($val ? (OLBP::result_tips() . "<p>Additional b") : "<p>B");
      print "ooks from the extended shelves:</p>";
      showauthorhits($store, (split '\s+', $exval));
    }
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

sub _livelink {
  my ($self, $item, $link, $coll, $cmd) = @_;
  if (!$link) {
    $link = $item;
  }
  my $url = _get_query_url($link, $cmd);
  if ($url) {
    return "<a href=\"$url\">" . $item . "</a>";
  }
  return OLBP::html_encode($item);
}

sub _print_related_list {
  my ($self, $header, $noplural, @list) = @_;
  my $size = scalar(@list);
  if ($size) {
    print "<b>$header" . (($size == 1 || $noplural) ? "" : "s");
    print ":</b><ul>";
    foreach my $item (@list) {
      print "<li>" . $self->_livelink($item) . "</li>";
    }
    print "</ul>";
  }
}

sub display {
  my ($self, %params) = @_;
  my $name = $self->get_heading();
  my $informal = $self->get_informal();
  my $desc = $self->_get_string_from_file("wplead");
  my $hasbooksabout = 0;
  my $includewikipedia = 1;
  if (!$informal) {
    $informal = OLBP::Name::informal($name);
  }
  $self->_display_banner($name, $informal);
  print qq!<table><tr><td class="agentinfo">\n!;
  if ($desc) {
    $self->_print_lead($desc);
    $includewikipedia = 0;
  } 
  $self->_print_additional_refs($name, $includewikipedia);
  my @roles = ();
  my $roleref = $self->get_roles();
  if ($roleref) {
    @roles = @{$roleref};
  }
  if (scalar(@roles)) {
    $self->_print_roles(@roles);
  }
  my $akey = OLBP::BookRecord::sort_key_for_name($name);
  my $val = gethashval("authortitles", $akey);
  my $exval = gethashval("authortitles", $akey, $extradir);
  my $skey = OLBP::BookRecord::search_key_for_subject($name);
  my @subjectbooks = $self->{subbrowser}->get_books_with_subject(key=>$skey);
  # for extended shelves; see _lookup_key in SubjectHierarchyBrowser
  my $subjectnotes = gethashval("booksubnotes", $skey);
  if ($subjectnotes) {
    my $node = new OLBP::SubjectNode(name => $name);
    $node->expand(infostring=>$subjectnotes);
    $self->_print_related_list("Example of", 1, $node->broader_terms());
    $self->_print_related_list("More specific subject", 0,
                               $node->narrower_terms());
  }
  print qq!</td><td class="separator">&nbsp;!;
  print qq!</td><td class="agentworks">!;
  if (scalar(@subjectbooks)) {
    $hasbooksabout = 1;
    if ($val || $exval) {
      print qq!<p><a href="#booksabout">Books about $informal</a> -- 
                  <a href="#booksby">Books by $informal</a></p>!;
    }
  }
  if ($hasbooksabout) {
    # might need better way to get subs when nothing filed directly under name
    print "<p id=\"booksabout\"><strong>Books about $informal:</strong></p>";
    $self->{subbrowser}->show_books_under_subject(term=>$name, max=>50,
                                                  downonly=>1);
    # Only show the extended shelves ones directly under the name
    #  (which may mean the narrower terms should be displayed on the left)
  }
  if ($val || $exval) {
    print "<p id=\"booksby\"><strong>Books by $informal:</strong><p>";
    $self->display_works(curatedbookvals=>$val, extendedbookvals=>$exval);
  }
  print "</td></tr></table>";
}

sub picfilename {
  my ($self, %params) = @_;
  if (!$self->{picfile}) {
    if (!$self->{nopicfile}) {
      if ($self->{stubdir}) {
        my $dir = $picpath . $self->{stubdir};
        my $globpattern = "$dir/$self->{id}.*";
        my @filenames = glob($globpattern);
        if (scalar(@filenames)) {
           my $filename = $filenames[0];
           $filename =~ s/.*\///;
           $self->{picfile} = $filename;
        } else {
          $self->{nopicfile} = 1;  # Don't keep trying to find an absent file
        }
      }
    }
  }
  return $self->{picfile};
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{id} = $params{id};
  if ($self->{id} =~ /Q(.*)/) {
    $self->{stubdir} = sprintf("%02d", int($1) % 100);
  }
  $self->{authornote} = $params{authornote};
  $self->{dir} = $params{dir};
  $self->{subbrowser} = $params{subbrowser};
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
