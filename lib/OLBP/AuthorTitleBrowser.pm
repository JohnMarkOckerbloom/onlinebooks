package OLBP::AuthorTitleBrowser;
use OLBP::OLBPBrowser;
@OLBP::AuthorTitleBrowser::ISA = qw(OLBP::OLBPBrowser);
use strict;

sub get_alias {
  my ($self, $idx) = @_;
  if ($self->{cachedalias}->{$idx}) {
    return $self->{cachedalias}->{$idx};
  }
  my $alias = "";
  my ($key, $id) = $self->{indexer}->get_slot(index=>$idx);
  return undef if (!$key || !$id);
  if ($id =~ /^-A(\d+)/) {
    $alias = $1;
  }
  $self->{cachedalias}->{$idx} = $alias;
  return $alias;
}

sub _get_author_browser {
  my $self = shift;
  if (!$self->{ab}) {
    $self->{ab} = new OLBP::AuthorBrowser(collection=>$self->{collection});
  }
  return $self->{ab};
}

sub get_item_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my $alias = $self->get_alias($idx);
  if ($alias ne "") {
    my $idx = $alias;
    my $ab = $self->_get_author_browser();
    return $ab->get_item_name(index=>$idx);
  }
  my ($key, $br, $pos) = $self->get_key_and_bookrecord($idx);
  if ($br) {
    return $br->get_formal_name(index=>$pos) . ": " . $br->get_title();
  }
  return undef;
}

sub get_item_display {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my $alias = $self->get_alias($idx);
  if ($alias ne "") {
    my $idx = $alias;
    my $ab = $self->_get_author_browser();
    return $ab->get_item_display(index=>$idx);
  }
  my ($key, $br, $pos) = $self->get_key_and_bookrecord($idx);
  if ($br) {
    return $br->short_entry(useauthor=>$pos);
  }
  return undef;
}

sub range_note {
  my ($self, %params) = @_;
  my $url = $OLBP::scripturl . '/browse?type=author';
  if ($params{startname}) {
    my $key = $params{startname};
    $key =~ s/\:.*//;
    $url .= "&amp;key=" . OLBP::url_encode($key);
  }
  if ($self->{collection} eq "x") {
    $url .= "&amp;c=x";
  }
  my $parenthesized =  "<a href=\"$url\">Hide titles</a>";
  my $ourl = $OLBP::scripturl . '/browse?type=atitle';
  if ($params{startname}) {
    my $key = $params{startname};
    $ourl .= '&amp;key=' . OLBP::url_encode($key);
  }
  my $msg = "Include extended shelves";
  if ($self->{collection} eq "x") {
    $msg = "Exclude extended shelves";
  } else {
    $ourl .= "&amp;c=x";
  }
  $parenthesized .=  "; <a href=\"$ourl\">$msg</a>";
  return " ($parenthesized)";
}

sub supply_sort_key {
  my $str = $_[1];
  if (!($str =~ /$OLBP::authortitlesep/)) {
    $str =~ s/:\s+/$OLBP::authortitlesep/;
  }
  if ($str =~ /(.*)$OLBP::authortitlesep(.*)/) {
    $str = OLBP::BookRecord::sort_key_for_name($1)
             . $OLBP::authortitlesep 
             . OLBP::BookRecord::sort_key_for_title($2);
    return substr($str, 0, $OLBP::atsortkeylimit);
  }
  return OLBP::BookRecord::sort_key_for_name($str);
}

sub nomatch_message {
  my ($self, $givenkey) = @_;
  my $msg = "No exact match for ";
  $givenkey =~ s/\x02/,/g;
  $givenkey =~ s/$OLBP::authortitlesep/: /g;
  $givenkey =~ s/[\x00-\x1f]/ /g;
  $msg .= OLBP::html_encode($givenkey) . ". Showing nearby items.";
  return $msg;
}

sub items_name { return "Authors With Titles";}

sub browse_type { return "atitle";}

# we have info links here, so no dot necessary
sub start_list {return "<ul class=\"nodot\">\n";}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection} = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/";
  }
  my $iname = OLBP::indexfilename("authorrefs", $dir),
  $self->{store} = new OLBP::RecordStore(dir=>$OLBP::dbdir);

  $self->{indexer} = new OLBP::Index(name=>"authorrefs",
                                     filename=>$iname, cache=>1);
  return $self->SUPER::_initialize(%params);
}

1;


