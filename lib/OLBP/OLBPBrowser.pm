package OLBP::OLBPBrowser;
use OLBP::Browser;
@OLBP::OLBPBrowser::ISA = qw(OLBP::Browser);
use strict;

# Here are some generic routines that are common across
# OLBP-style browsing.  (Though we can still override them if desired)
# This is a virtual class; to be usable, some routines have to be
# filled in from elsewhere

# get_bookrecord is a generic routine for getting a bookrecord from our
# indexer, given a supplied index

sub get_key_and_bookrecord {
  my ($self, $idx) = @_;
  if ($self->{cachedkey}->{$idx}) {
    return ($self->{cachedkey}->{$idx},
            $self->{cachedbr}->{$idx},
            $self->{cachedpos}->{$idx});
  }
  my ($key, $id) = $self->{indexer}->get_slot(index=>$idx);
  return undef if (!$key || !$id);
  my $pos;
  if ($id =~ /(.*):(.*)/) {
    ($id, $pos) = ($1, $2);
  }
  # my $str = $self->{entryhash}->get_value(key=>$id);
  # return undef if (!$str);
  # my $br = new OLBP::BookRecord(string=>$str);
  # print "\n<!-- For idx $idx, I get key $key and the ID i need is $id and pos $pos -->\n";
  my $br = $self->{store}->get_record(id=>$id);
  return undef if (!$br);
  $self->{cachedkey}->{$idx} = $key;
  $self->{cachedbr}->{$idx} = $br;
  $self->{cachedpos}->{$idx} = $pos;
  return ($key, $br, $pos);
}

# Here's our usual generic "no match" method (overridden in some subclasses)

sub nomatch_message {
  my ($self, $givenkey) = @_;
  my $msg = "No exact match for ";
  $givenkey =~ s/[\x00-\x1f]/ /g;
  $msg .= OLBP::html_encode($givenkey) . ". Showing nearby items.";
  return $msg;
}

# Here's how we generally handle finding correct slots
# (Note that supply_sort_key gets provided in our subclasses)

sub find_right_slot {
  my ($self, %params) = @_;
  my $givenkey = $params{key};
  my $givenidx = $params{index};
  my $msg;

  $givenkey = $self->supply_sort_key($givenkey);
  if ($givenidx >= 0) {
    my ($first, $ignore) = $self->{indexer}->get_slot(index=>$givenidx);
    if ($givenkey eq substr($first, 0, length($givenkey))) {
      return ($givenidx, undef);
    }
  }
  my $slot = $self->{indexer}->closest_index(key=>$givenkey);
  my $isize = $self->get_index_size();
  if ($slot >= $isize) {
    $slot = $isize - 1;
  }
  my ($first, $ignore) = $self->{indexer}->get_slot(index=>$slot);
  # print "\n<!-- Trying to get $givenkey; settled on $first in slot $slot -->\n";
  if ($givenkey ne substr($first, 0, length($givenkey))) {
    $msg = $self->nomatch_message($givenkey);
    $slot -= 1;
  }
  if ($slot < 0) {
    $slot = 0;
  }
  return ($slot, $msg);
}

sub good_match {
  my ($self, %params) = @_;
  my $givenkey = $params{key};
  my $givenidx = $params{index};

  $givenkey = $self->supply_sort_key($givenkey);
  if ($givenidx >= 0) {
    my ($first, $ignore) = $self->{indexer}->get_slot(index=>$givenidx);
    if ($givenkey eq substr($first, 0, length($givenkey))) {
      return 1;
    }
  }
  return 0;
}

sub get_index_size { return shift->{indexer}->get_size();}

sub get_query_url {
  my ($self, %params) = @_;
  my $slot = $params{index};
  my $type = $self->browse_type();
  my ($qkey, $junk) = $self->{indexer}->get_slot(index=>$slot);
  my $collarg = ($self->{collection} ? ("&amp;c=" . $self->{collection}) : "");
  if ($qkey) {
    return $OLBP::scripturl
            . "/browse?type=$type&amp;index=$slot&amp;key="
            . OLBP::url_encode($qkey)
            . $collarg;
  }
  return "";
}

sub quick_picks {
  my ($self, %params) = @_;
  my $type = $self->browse_type();
  my $querypat = $OLBP::scripturl . "/browse?type=$type&amp;key=%s";
  if ($self->{collection}) {
    $querypat .= "&amp;c=" . $self->{collection};
  }
  return $self->choice_list(pattern=>$querypat, list=>['A'..'Z']);
}

sub jump_form {
  my ($self, %params) = @_;
  my $type = $self->browse_type();
  my $coll = $self->{collection};
  my $caption = $params{caption} || "Or start at this prefix";
  $caption = qq!<label for="key">$caption</label>!;
  return "<form method=\"GET\" action=\"$OLBP::scripturl/browse\">\n" .
         "$caption: " .
         "<input type=\"hidden\" name=\"type\" value=\"$type\">\n" .
         "<input type=\"hidden\" name=\"c\" value=\"$coll\">\n" .
         "<input name=\"key\" id=\"key\" size=10 value=\"\"></form>\n";
}

sub _initialize {
  my ($self, %params) = @_;
  return $self->SUPER::_initialize(%params);
}

sub start_list {return "<ul>\n";}

sub end_list {return "</ul>\n";}

sub early_end_marker {return "</ul><p><b>End of list.</b></p><ul>\n";}

sub item_in_list {
  my ($self, %params) = @_;
  return "<li>" . $params{string} . "</li>\n";
}

1;


