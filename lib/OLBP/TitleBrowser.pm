package OLBP::TitleBrowser;
use OLBP::OLBPBrowser;
@OLBP::TitleBrowser::ISA = qw(OLBP::OLBPBrowser);
use strict;

sub get_item_name {
  my ($self, %params) = @_;
  my $idx = $params{index};
  my ($key, $br) = $self->get_key_and_bookrecord($idx);
  if ($br) {
    return $br->get_title();
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

sub range_note {
  my ($self, %params) = @_;
  my $url = $OLBP::scripturl . '/browse?type=title';
  if ($params{startname}) {
    my $key = $params{startname};
    $url .= "&amp;key=" . OLBP::url_encode($key);
  }
  my $msg = "Include extended shelves";
  if ($self->{collection} eq "x") {
    $msg = "Exclude extended shelves";
  } else {
    $url .= "&amp;c=x";
  }
  return " (<a href=\"$url\">$msg</a>)";
}

# This is for the search routines, so they can pull out an ID for sorting

sub get_ref_id {
  my ($self, $idx) = @_;
  my ($key, $id) = $self->{indexer}->get_slot(index=>$idx);
  return $id;
}

sub supply_sort_key { return OLBP::BookRecord::sort_key_for_title($_[1]);}

sub items_name { return "Titles";}

sub browse_type { return "title";}

# we have info links here, so no dot necessary
sub start_list {return "<ul class=\"nodot\">\n";}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = "";
  $self->{collection} = $params{collection};
  if ($self->{collection} eq "x") {
    $dir = $OLBP::dbdir . "exindexes/";
  }
  $self->{store} = new OLBP::RecordStore(dir=>$OLBP::dbdir);
  my $iname = OLBP::indexfilename("titles", $dir);

  $self->{indexer} = new OLBP::Index(name=>"titles",
                                     filename=>$iname, cache=>1);
  return $self->SUPER::_initialize(%params);
}

1;


