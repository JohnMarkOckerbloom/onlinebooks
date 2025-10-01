package OLBP::AgentPage;
use OLBP::Name;
use OLBP::RecordStore;
use JSON;
use RelationshipConstants;

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
  my $info = $self->get_image_info();
  my $class = "whobanner";
  if (!$info) {
   $class = "whobanner-nopic";
  }
  print qq!<div class="$class">!;
  print qq!<table><tr><td>! if ($info);
  print "<h2>$informal</h2>\n";
  my $naivename = OLBP::Name::naive($name);
  if (($naivename ne $informal) && ($informal ne $name)) {
    print "<h3>($name)</h3>\n";
  }
  if ($info) {
    print qq!</td><td style="width: 15%"></td><td>!;
    my $desc = $info->{desc};
    my $title = $info->{title};
    $desc =~ s/\<[^\>]+\>//g;                  # strip out HTML markup
    my $picfile = $self->picfilename();
    my $picdir = $self->{stubdir};
    # print "<b>desc is $desc, title is $title, picdir is $picdir, picfile is $picfile</b>\n";
    if ($picfile && $picdir) {
      my $imageurl = "$imagestub$picdir/$picfile";
      my $commonsurl = $commonsstub . OLBP::url_encode($title);
      _display_image($imageurl, $desc, $commonsurl);
    }
  }
  print qq!</td></tr></table>! if ($info);
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

sub _get_rels {
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

# always returns a list (sometimes empty)
# can be filtered by type and/or description

sub get_relationships {
  my ($self, %params) = @_;
  my $rels = $self->_get_rels();
  return () if (!$rels);
  my @list = @{$rels};
  if ($params{type} || $params{description}) {
    my @newlist = ();
    foreach my $item (@list) {
      next if ($params{type} && $item->{type} ne $params{type});
      next if ($params{description}
       && $item->{description} ne $params{description});
     push @newlist, $item;
    }
    @list = @newlist;
  }
  return @list;
}

sub _print_relationship {
  my ($self, $rel, $usedesc) = @_;
  if ($rel->{description} eq "Ambassador") {
    print $self->_wholink($rel->{objectname}) . " ";
    if ($usedesc) {
      print $rel->{description}.  " to ";
    }
    print $self->_wholink($rel->{object2name});
  } else {
    if ($usedesc) {
      print ($rel->{description});
      print ", " if ($rel->{objectname});
    }
    if ($rel->{objectname}) {
      print $self->_wholink($rel->{objectname});
    }
  }
  if ($rel->{date1} || $rel->{date2}) {
    if (!$rel->{date2} || ($rel->{date1} eq $rel->{date2})) {
      print " ($rel->{date1})";
    } else {
      print " ($rel->{date1}\-$rel->{date2})";
    }
  }
}

sub _print_relationships {
  my ($self, $name, $usedesc, @roles) = @_;
  if (scalar(@roles) > 1) {
    $name = RelationshipConstants::pluralize($name);
  }
  print "\n<b>$name:</b><ul>\n";
  foreach my $role (sort {$a->{start} <=> $b->{start} } @roles) {
    print "<li> ";
    $self->_print_relationship($role, $usedesc);
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
  my $informal = $self->get_informal();
  if ($includewp) {
    my $wpurl = $self->get_wikipedia_url();
    if ($wpurl)  {
      my $ref = {"note"=>"Wikipedia article", "url"=>$wpurl};
      push @refs, $ref;
    }
  }
  print "<b>More about $informal:</b><ul>\n";
  foreach my $ref (@refs) {
    print "<li> <a href=\"$ref->{url}\">$ref->{note}</a>";
  }
  my $url = $OLBP::seealsourl . "?su=" . OLBP::url_encode($name);
  print "<li> <a href=\"$url\">Resources in your library</a>";
  $url .= "\&amp;library=0CHOOSE0";
  print "<li> <a href=\"$url\">Resources in another library</a>";
  print "</ul>";
}

sub _print_lead {
  my ($self, $str) = @_;
  my $wpurl = $self->get_wikipedia_url();
  $str =~ s!\'\'\'(.*)?\'\'\'!<b>$1</b>!g;
  $str =~ s!</b>\s*\(.*?\)!</b>!;         # remove parenthetical after boldname
  $str =~ s!\(\s*;\s*!\(!;                # remove semicolons after paren
  $str =~ s!\(\s*\)!!;                    # remove empty parenthetical
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
      if ($val) {
        # print OLBP::result_tips();
        my $byslug = "by " . $self->get_informal();
        print "<details><summary>";
        print "Additional books $byslug in the extended shelves:</summary>";
      } else {
        print "Books $byslug in the extended shelves:";
      }
      showauthorhits($store, (split '\s+', $exval));
      if ($val) {
        print "</details>";
      }
    }
  }
  print "<p>";
  print "Find more by ". $self->get_informal() . " at ";
  my $name = $self->get_heading();
  my $url = $OLBP::seealsourl . "?au=" . OLBP::url_encode($name);
  print "<a href=\"$url\">your library</a>, or ";
  print "<a href=\"$url\&amp;library=0CHOOSE0\">elsewhere</a>.";
  print "</p>\n";
}

sub _get_query_url {
  my ($term, $cmd) = @_;
  if ($term) {
    $cmd ||= "/browse?type=lcsubc";
    return $OLBP::scripturl . "$cmd&amp;key=" . OLBP::url_encode($term);
  }
  return "";
}

sub _wholink {
  my ($self, $item) = @_;
  my $url = $OLBP::whourl . "/" . OLBP::url_encode($item);
  return "<a href=\"$url\">" . $item . "</a>";
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

sub _show_extended_about {
  my ($self, @booklist) = @_;
  my $type = "subject";
  print qq!<div id="xsubjectbooks">!;
  print "<details><summary>";
  print scalar(@booklist) .  " additional book";
  print "s" if (scalar(@booklist) > 1);
  print " about " . $self->get_informal();
  print " in the extended shelves:</summary>";
  print "<ul>";
  foreach my $br (@booklist) {
     print "<li>" . $br->short_entry() . "</li>\n";
  }
  print "</ul>";
  print "</details>";
  print "</div>\n";
}

# Since extended shelves include curated collection too, we'll filter those out

sub _filter_out_curated {
  my (@booklist) = @_;
  my @newlist = ();
  foreach my $book (@booklist) {
    if (!($book->get_id() =~ /^olbp/)) {
      push @newlist, $book;
    }
  }
  return @newlist;
}

sub _print_notes {
  my ($self, %params) = @_;
  my $note = $self->{authornote};
  if ($note) {
    my @miscnotes = $note->get_misc_notes();
    if (scalar(@miscnotes)) {
      foreach my $miscnote (@miscnotes) {
        # May eventually want to support {bracket-codes}
        print "<p>" . $miscnote. "</p>\n";
      }
    }
    my @aliases = $note->get_aliases();
    if (scalar(@aliases)) {
      print "<b>Also found under:</b><ul>\n";
      foreach my $alias (@aliases) {
        print "<li> $alias";
      }
      print "</ul>\n";
    }
  }
}

# This adds to the SEE_ALSO relationship those relations
# that are explicitly mentioned in our catalog file

sub _add_explicit_xrefs {
  my ($self, %params) = @_;
  my $authornote = $self->{authornote};
  if ($authornote)  {
    my @xrefs = $authornote->get_xrefs();
    if (scalar(@xrefs)) {
      foreach my $xref (@xrefs) {
        my $rel = {};
        $rel->{description} = $RelationshipConstants::SEEALSO;
        $rel->{objectname} = $xref;
        if (!$self->{rels}) { 
          $self->{rels} = [];
        }
        push @{$self->{rels}}, $rel;
      }
    }
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
  $self->_print_notes();
  $self->_print_additional_refs($name, $includewikipedia);
  my @roles = $self->get_relationships(type=>"Role");
  if (scalar(@roles)) {
    $self->_print_relationships("Selected roles", 1, @roles);
  }
  $self->_add_explicit_xrefs();
  foreach my $reltype ($RelationshipConstants::SEEALSO,
                       $RelationshipConstants::CREATED,
                       $RelationshipConstants::CREATEDBY,
                       $RelationshipConstants::ASSOCIATED) {
    my @names = $self->get_relationships(description=>$reltype);
    if (scalar(@names)) {
      $self->_print_relationships($reltype, 0, @names);
    }
  }
  my $akey = OLBP::BookRecord::sort_key_for_name($name);
  my $val = gethashval("authortitles", $akey);
  my $exval = gethashval("authortitles", $akey, $extradir);
  my $skey = OLBP::BookRecord::search_key_for_subject($name);
  my @subjectbooks = $self->{subbrowser}->get_books_with_subject(key=>$skey);
  my @xsubjectbooks = $self->{xsubbrowser}->get_books_with_subject(key=>$skey);
  @xsubjectbooks = _filter_out_curated(@xsubjectbooks);
  my $subjectnotes = gethashval("booksubnotes", $skey);
  if ($subjectnotes) {
    $hasbooksabout = 1;
    my $node = new OLBP::SubjectNode(name => $name);
    $node->expand(infostring=>$subjectnotes);
    $self->_print_related_list("Example of", 1, $node->broader_terms());
    $self->_print_related_list("More specific subject", 0,
                               $node->narrower_terms());
  }
  print qq!</td><td class="separator">&nbsp;!;
  print qq!</td><td class="agentworks">!;
  if (scalar(@subjectbooks) || scalar(@xsubjectbooks)) {
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
    if (@xsubjectbooks) {
      $self->_show_extended_about(@xsubjectbooks);
    }
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
  $self->{xsubbrowser} = $params{xsubbrowser};
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
