package OLBP::SubjectGraph;
use strict;
use OLBP::Hash;
use OLBP::SubjectTweaks;
use OLBP::SubjectGeo;

my $idxdir = "./";
my $idxbuilddir = "indexbuild/";
my $hashes = {};

# subtype constants

my $PREFIX = 0;
my $AUTHORITY = 1;
my $GEOGRAPHY = 2;
my $LEXICAL = 3;

sub gethashval {
  my ($name, $key) = @_;

  return undef if (!$name);
  my $hash = $hashes->{$name};
  if (!$hash) {
    my $fname = OLBP::hashfilename($name, $idxdir);
    $hash = new OLBP::Hash(name=>$name, filename=>$fname, cache=>1);
    return undef if (!$hash);
    $hashes->{name} = $hash;
  }
  return $hash->get_value(key=>$key);
}

sub packhashtofile {
  my ($name, $hashref) = @_;
  my $fname = OLBP::hashfilename($name, $idxbuilddir);
  my $hash = new OLBP::Hash(name=>$name, filename=>$fname);
  return $hash->pack_to_file(hash=>$hashref);
}

sub find_node {
  my ($self, %params) = @_;
  my $key = $params{key};
  if (!$key) {
    my $heading = $params{heading};
    $key = OLBP::BookRecord::search_key_for_subject($heading);
  }
  return $self->{nodes}->{$key};
}

# For add_edge, we check the outbound side to see 
# if a relationship of the same type has already been defined for the node
# (we don't check inbound, as that should be superflous)

sub add_edge {
  my ($self, %params) = @_;
  my $type = $params{type};
  my $subtype = $params{subtype};
  my $note = $params{note};

  my $node1 = $params{node1};
  my $node2 = $params{node2};

  my $tuple = [$node1, $node2, $type, $subtype, $note];
  if ($self->{outbound}->{$node1}) {
    foreach my $tupleref (@{$self->{outbound}->{$node1}}) {
      if ($tupleref->[1] == $node2 && $tupleref->[2] eq $type) {
        # print "Already know that " . $node1->get_name() . " $type " .
        #       $node2->get_name() . "\n";
        return 0;
      }
    }
  }
  push @{$self->{outbound}->{$node1}}, $tuple;
  push @{$self->{inbound}->{$node2}}, $tuple;
  return 1;
}

sub _findid {
  my ($self, $heading) = @_;
  my $key = OLBP::BookRecord::search_key_for_subject($heading);
  return gethashval($self->{headingidhash}, $key);
}

# When a node is added:
#   -- Put it in the "unanalyzed" queue
#   -- Check its direct ancestors, and add them as necessary.
#       Establish parent-child relations as appropriate
# We return the node we create, if successful, or 0 otherwise

sub add_node {
  my ($self, %params) = @_;
  my $heading = $params{heading};
  $heading =~ s/^\s+//;
  $heading =~ s/\s+$//;
  return 0 if (!$heading);
  my $key = OLBP::BookRecord::search_key_for_subject($heading);
  my $checknode = $self->find_node(key=>$key);
  if ($checknode) {   # already exists
    if ($params{improve}) {
      # If we're asked to improve the name,
      # replace the existing name if this one starts with a capital,
      # or doesn't end with a period
      my $oldname = $checknode->get_name();
      if ($oldname ne $heading) {
        if ($heading =~ /^[A-Z]/) {
          $checknode->set_name($heading);
        } elsif ($oldname =~ /\.\s*$/ && !($heading =~ /\.\s*$/)) { 
          $checknode->set_name($heading);
        }
      }
    } 
    return 0;
  }
  my $id = $self->_findid($heading);
  my $node = new OLBP::SubjectNode(name=>$heading, id=>$id);
  $self->{nodes}->{$key} = $node;
  push @{$self->{unanalyzed}}, $node;
  my $superhead = $node->get_parent_name();
  if ($superhead) {
    my $supernode = $self->find_node(heading=>$superhead);
    if (!$supernode) {
      $supernode = $self->add_node(heading=>$superhead);
    }
    if ($supernode) {
      $self->add_edge(node1=>$node, node2=>$supernode,
                         type=>"BT", subtype=>$PREFIX);
    }
  }
  return $node;
}

# When it's time to expand the graph:
#   -- While there are nodes in the "unanalyzed", pull one out, and
#       -- See if it has an authority record (or proxy), If so, read it in,
#                 record its id, and 
#           -- add scope notes
#           -- add call number info
#           -- assign aliases (if any; aliases are not nodes for now)
#           -- check broader terms.  If not there yet, add them (in
#               "unanalyzed" queue.  Establish broader-narrowe relations as app.
#           -- check for geographically broader terms. If exist or authorized,
#               make that relationship as well (and add them in "unanalyzed"
#                queue if not in yet.)
#           -- record related term candidates, but don't add to graph yet
#       -- Put it in the "unlexed" queue if facets exist,
#            otherwise to "unrelated" queue
#  -- When nothing's left in the "unanalyzed" queue, move to "unlexed" queue
#       -- See if removing facets *not* at the end yields existing
#             OR authorized headings.  If so:
#                if not existing, add node in "unanalyzed" queue
#               Estabish broader-narrower relations as appropriate.
#       -- When done, move to "unrelated" queue
#  -- When nothing's left in either queue, move to "unrelated" queue
#        For each node, look at related term candidates, and *if* they're
#        in graph, add relations as appropriate.  Remove from queue.
#     When all queues are empty, we're done!

# TODO: Try to expand broader terms further up the direct ancestry tree; 
# e.g. Pennsylvania -- History -- Civil War, 1861-1865 should be under
#      United States -- History -- Civil War, 1861-1865
# by virtue of Pennsylvania being under United States.  (Only do it
#  if the broader term is is use).  When to do this?  Perhaps after
#  the lexing stage?

sub expand {
  my ($self, %params) = @_;
  while (scalar(@{$self->{unanalyzed}}) ||
         scalar(@{$self->{unlexed}})    ||
         scalar(@{$self->{unrelated}})) {
    # print scalar(@{$self->{unanalyzed}}) . " -- " .
    #      scalar(@{$self->{unlexed}})    . " -- " . 
    #      scalar(@{$self->{unrelated}}) . "\n";
    if (scalar(@{$self->{unanalyzed}})) {
      my $node = shift @{$self->{unanalyzed}};
      my $heading;
      my $id = $node->get_id();
      if ($id) {
        my $infostr = gethashval($self->{idinfohash}, $id);
        if ($self->{tweaks}) {
          $heading ||= $node->get_name();
          if ($heading) {
            $infostr .= $self->{tweaks}->get_tweak_string(heading=>$heading);
          }
        }
        $node->expand(infostring=>$infostr);
        my @terms = $node->broader_terms();
        foreach my $term (@terms) {
          my $parent = $self->find_node(heading=>$term);
          if (!$parent) {
            $parent = $self->add_node(heading=>$term);
          }
          if ($parent) {
            $self->add_edge(node1=>$node, node2=>$parent,
                            type=>"BT", subtype=>$AUTHORITY);
          }
        }
      }
      if ($self->{geo}) {
        $heading ||= $node->get_name();
        if ($heading && !($heading =~ /--/)) {
          my @gparents = $self->{geo}->get_geoparents(heading=>$heading);
          foreach my $gterm (@gparents) {
            my $parent = $self->find_node(heading=>$gterm);
            if (!$parent && $self->_findid($gterm)) {
              $parent = $self->add_node(heading=>$gterm);
            }
            if ($parent) {
              $self->add_edge(node1=>$node, node2=>$parent,
                              type=>"BT", subtype=>$GEOGRAPHY);
            }
          }
        }
      }
      if ($node->get_parent_name()) {
        push @{$self->{unlexed}}, $node;
      } else {
        push @{$self->{unrelated}}, $node;
      }
    } elsif (scalar(@{$self->{unlexed}})) {
      my $node = shift @{$self->{unlexed}};
      my @terms = $node->shorter_possibilities();
      if (scalar(@terms)) {
        for (my $i = scalar(@terms) -1; $i >= 0; $i--) {
          my $term = $terms[$i];
          next if (!$term);
          if ($self->{geo} && !$self->find_node(heading=>$term) &&
              !$self->_findid($term)) {
            $term = $self->{geo}->get_geoheading(heading=>$term);
          }
          if ($self->find_node(heading=>$term) ||
               $self->_findid($term)) {
            for (my $j = 0; $j < $i; $j++) {
              if (($j | $i) == $i) {
                 $terms[$j] = "";   # eliminate overshort facet lineups
              }
            }
            my $parent = $self->find_node(heading=>$term);
            if (!$parent) {
              $parent = $self->add_node(heading=>$term);
            }
            if ($parent) {
              $self->add_edge(node1=>$node, node2=>$parent,
                             type=>"BT", subtype=>$LEXICAL);
            }
          } else {
            $terms[$i] = "";  
          }
        }
      }
      # Now see if you can substitute the first component with a BT
      # fot that component (only by authority or geo., not by prefix or lex)
      my $heading ||= $node->get_name();
      if ($heading) {
        if ($heading =~ /(.*?)\s+--\s+(.*)/) {
          my ($first, $rest) = ($1, $2);
          if ($first) {
            my $fnode = $self->find_node(heading=>$first);
            if ($fnode) {
              foreach my $tupleref (@{$self->{outbound}->{$fnode}}) {
                next if ($tupleref->[2] ne "BT" || $tupleref->[3] == $PREFIX ||
                         $tupleref->[3] == $LEXICAL);
                my $cand = ($tupleref->[1] ? $tupleref->[1]->get_name() : "");
                if ($cand) {
                  my $newterm = "$cand -- $rest";
                  my $parent = $self->find_node(heading=>$newterm);
                  if (!$parent && $self->_findid($newterm)) {
                    $parent = $self->add_node(heading=>$newterm);
                  }
                  if ($parent) {
                    $self->add_edge(node1=>$node, node2=>$parent,
                                     type=>"BT", subtype=>$tupleref->[3]);
                  }
                }
              }
            }
          }
        }
      } 
      push @{$self->{unrelated}}, $node;
    } elsif (scalar(@{$self->{unrelated}})) {
      my $node = shift @{$self->{unrelated}};
      my @terms = $node->related_terms();
      foreach my $term (@terms) {
        my $neighbor = $self->find_node(heading=>$term);
        if ($neighbor) {
            # RT should be symmetrical -- we'll do both sides to be sure
            $self->add_edge(node1=>$node, node2=>$neighbor,
                             type=>"RT", subtype=>$AUTHORITY);
            $self->add_edge(node1=>$neighbor, node2=>$node,
                             type=>"RT", subtype=>$AUTHORITY);
        }
      }
    }
  }
}

# We are sorting narrower term tuples in the order we think our
# will want to see them.  
# First, prefix
# Then, by authority
# Then, geographic
# Then, lexical
# Within each group, alphabetically (though we may get more sophisticated
# later on)

sub _sort_narrow {
  return sort {
    ($a->[3] <=> $b->[3]) || 
    ($a->[0]->get_name() cmp $b->[0]->get_name());
  } @_;
}

sub _sort_rel {
  return sort {
    (($a->[2] cmp $b->[2]) || 
     ($a->[3] <=> $b->[3]) || 
     ($a->[0]->get_name() cmp $b->[0]->get_name()));
  } @_;
}


sub _output_string {
  my ($self, $key, $node) = @_;
  my $str = "";
  foreach my $val ($node->scope_notes()) {
    $str .= "SN $val\n";
  }
  foreach my $val ($node->aliases()) {
    # suppress aliases actually in use
    if (!($self->find_node(heading=>$val))) {
      $str .= "UF $val\n";
    }
  }
  # do BT and RT
  if ($self->{outbound}->{$node}) {
    my @tuplist = ();
    foreach my $tupleref (@{$self->{outbound}->{$node}}) {
      if ($tupleref->[2] =~ /(BT|RT)/) {
        push @tuplist, $tupleref;
      }
    }
    @tuplist = _sort_rel(@tuplist);
    foreach my $tupleref (@tuplist) {
      my $label = $tupleref->[2];
      my $othernode = $tupleref->[1];
      if ($othernode) {
        my $heading = $othernode->get_name();
        if ($heading) {
          $str .= "$label $heading\n";
        }
      }
    }
  }
  # now do NT
  if ($self->{inbound}->{$node}) {
    my @tuplist = ();
    foreach my $tupleref (@{$self->{inbound}->{$node}}) {
      if ($tupleref->[2] eq "BT") {
        push @tuplist, $tupleref;
      }
    }
    @tuplist = _sort_narrow(@tuplist);
    foreach my $tupleref (@tuplist) {
      my $othernode = $tupleref->[0];
      if ($othernode) {
        my $heading = $othernode->get_name();
        if ($heading) {
          $str .= "NT $heading\n";
        }
      }
    }
  }
  return $str;
}

# This writes out a hash of each heading and its notes
# with xrefs sorted appropriately (for now, we just sort narrower
# terms; there's sometimes a lot of those)

sub output {
  my ($self, %params) = @_;
  my ($headkey, $node);
  my $outputhashname = $params{outputhash} || $self->{outputhash};
  my %subjstr = ();
  while (($headkey, $node) = each %{$self->{nodes}}) {
    my $str = $self->_output_string($headkey, $node);
    $subjstr{$headkey} = $str;
  }
  packhashtofile($outputhashname, \%subjstr);
}

# This returns a ref. to a hash of headings (both real and alias)
# values are as follows:
# . - real heading, no subcategories
# + - real heading, subcategories
# [ptr...] (a ref. to an array of pointers to real headings) alias

sub headingshash {
  my ($self, %params) = @_;
  my $hash = {};
  my ($headkey, $node);
  # first do real nodes
  while (($headkey, $node) = each %{$self->{nodes}}) {
    my $val = ".";
    if ($self->{inbound}->{$node}) {
      foreach my $tupleref (@{$self->{inbound}->{$node}}) {
        if ($tupleref->[2] eq "BT") {
          $val = "+";
          last;
        }
      }
    }
    my $heading = $node->get_name();
    $hash->{$heading} = $val;
  }
  # now pick up aliases not already in headings
  while (($headkey, $node) = each %{$self->{nodes}}) {
    foreach my $val ($node->aliases()) {
      if (!$hash->{$val}) {
        $hash->{$val} = [$node];
      } elsif (ref($hash->{$val})) {
        push @{$hash->{$val}}, $node;
      }
    }
  }
  return $hash;
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{nodes} = {};
  $self->{unanalyzed} = [];
  $self->{unlexed} = [];
  $self->{unrelated} = [];
  $self->{headingidhash} = $params{headingidhash};
  $self->{idinfohash} = $params{idinfohash};
  $self->{outputhash} = $params{outputhash};
  $self->{tweaks} = $params{tweaks};
  $self->{geo} = $params{geo};
  if (!$self->{headingidhash} || !$self->{idinfohash}) {
    print "Hey, where did everyone go?\n";
    return 0;
  }
  # print "Okay, here we go!\n";
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
