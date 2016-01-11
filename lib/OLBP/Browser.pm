package OLBP::Browser;

# Some virtual functions that should be overridden in subtypes

sub find_right_slot {
  my ($self, %params) = @_;
  return ($params{index}, "");
}

sub get_index_size {return 0;}

sub items_name {return "Items";}

sub range_note {return "";}

sub get_item_name {return "";}

sub get_query_url {return "";}

sub quick_picks {return "";}

sub jump_form {return "";}

sub start_list {return "";}
sub end_list {return "";}
sub early_end_marker {return "";}

sub item_in_list {
  my ($self, %params) = @_;
  return $params{string};
}

# End of virtual functions

# Some helper functions currently implemented here since they're
# fairly generic.  Some of these may move down into subclasses later
# on if they turn out to be not so generic
# (though navigation_line must be implemented somewhere, under this
# class's display_browse implementation)

sub navigation_line {
  my ($self, %params) = @_;
  my $slot = $params{slot};
  my $backslot = $params{backslot};
  my $nextslot = $params{nextslot};
  my $isize = $params{isize};
  my $previcon = "&lt;previous";
  my $prevurl;
  my $str;

  if ($slot) {
    $prevurl = $self->get_query_url(index=>$backslot);
  }
  if ($prevurl) {
    $str = "<a href=\"$prevurl\">$previcon</a>";
  } else {
    $str = $previcon;
  }
  my $picks = $self->quick_picks();
  if ($picks) {
    $str .= " -- $picks -- ";
  } 
  my $nexticon = "next&gt;";
  my $nexturl;
  if ($nextslot < $isize) {
    $nexturl = $self->get_query_url(index=>$nextslot);
  }
  if ($nexturl) {
    $str .= "<a href=\"$nexturl\">$nexticon</a>";
  } else {
    $str .= $nexticon;
  }
  return $str;
}

# Displays the choices

sub choice_list {
  my ($self, %params) = @_;
  my $pattern = $params{pattern};
  if (!($params{list})) {
    return "";
  } 
  my @list = @{$params{list}};
  my $separator = " ";
  if (defined($params{separator})) {
    $separator = $params{separator};
  }
  my @linklist;
  foreach my $value (@list) {
    my $link = "<a href=\"" . sprintf($pattern, $value) . "\">$value</a>";
    push @linklist, $link;
  }
  return join $separator, @linklist;
}

# The public interface methods

sub display_browse {
  my ($self, %params) = @_;
  my $chunksize = $params{chunksize};

  my ($slot, $status) = $self->find_right_slot(%params);

  if ($status) {
    print "<p style=\"text-align:center\"><b>$status</b></p>";
  }

  my $isize = $self->get_index_size();

  my $backslot = $slot - $chunksize;
  if ($backslot < 0) {
    $backslot = 0;
  }
  my $nextslot = $slot + $chunksize;
  if ($nextslot > $isize) {
    $nextslot = $isize;
  }
  print "<p style=\"text-align:center\">";
  print "<b>Browsing " . $self->items_name();
  print "\n<!-- Settled on slot $slot, nextslot $nextslot-->\n";
  my $startname = $self->get_item_name(index=>$slot);
  my $endname = $self->get_item_name(index=>$nextslot-1);
  if ($startname && $endname) {
    print ": \"$startname\" to \"$endname\"";
  }
  print $self->range_note(startname=>$startname, endname=>$endname);
  print "</b></p>";
  my $navline = $self->navigation_line(slot=>$slot, nextslot=>$nextslot,
                                       backslot=>$backslot, isize=>$isize);
  if ($navline) {
    print "<p style=\"text-align:center\">$navline</p>";
  }
  my $jumpform = $self->jump_form();
  if ($jumpform) {
    print "<table style=\"margin-left: auto; margin-right: auto\">";
    print "<tr><td>$jumpform</td></tr></table>";
  }
  print $self->start_list();
  for (my $i = 0; $i < $chunksize; $i++) {
    my $str;
    if (($slot + $i) == $isize ||
        !($str = $self->get_item_display(index=>$slot+$i))) {
      print $self->early_end_marker();
      last;
    }
    print $self->item_in_list(index=>$slot+$i, string=>$str);
  }
  print $self->end_list();
  if ($navline) {
    print "<p style=\"text-align:center\">$navline</p>";
  }
  return 1;
}

sub _initialize {
  my ($self, %params) = @_;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

__END__

=head1 NAME

OLBP::Browser - A generic browsing class

=head1 SYNOPSIS

use OLBP::Browser

  $browser = new OLBP::Browser();
  $success = $browser->display_browse(%params);

  # virtual functions that need to be implemented in subclasses

  ($slot, $errormsg) = $browser->find_right_slot(%params);
  $htmlstuff         = $browser->get_item_display(index=>$slot);
  $number            = $browser->get_index_size();

  # virtual functions that enhance functionality if implemented in subclasses

  $name      = $browser->items_name();
  $htmlstuff = $browser->range_note(startname=>$startname, endname=>$endname);
  $name      = $browser->get_item_name(index=>$slot);
  $url       = $browser->get_query_url(index=>$slot);
  $htmlstuff = $browser->quick_picks();
  $htmlstuff = $browser->jump_form();

  $htmlstuff = $browser->start_list();
  $htmlstuff = $browser->end_list();
  $htmlstuff = $browser->early_end_marker();
  $htmlstuff = $browser->item_in_list(string=>$string, index=>$slot);

=head1 ABSTRACT

This Perl library provides a generic browser facility that can be
customized in various ways.

Browsing is basically looking at a section of an indexed list of
items, with various navigation tools given to move back and forth,
jump to other parts of the list, or change views.  (Future extensions
of this may also support various nonlinear browsing options; even now,
there's limited support for single-hierarchy overviews in the Online
Books Page call number browse, for instance.)

This library was originally written for The
Online Books Page, and hence is currently in the OLBP:: hierarchy.
A future version of this will probably be placed in a less 
application-specific hierarchy (such as PennLibrary::) and some
of the support functions may be moved out of the module at that time.

In order to be useful in a particular application, you will need
to create an appropriate subclass of Browser that implements some
of the virtual functions described here.  The subclass gives details
on the behavior of the browser, and its internal implementation.
Some of the more generic parts of browser behavior are implemented
in this class; if you want your browser to display differently,
you can always override those methods in your subclass.

=head1 DESCRIPTION

To browse, first create a new instance of the Browser object (in 
an appropriate subclass).   No parameters are defined at this level.
(In general, parameters of public methods are given as named
arguments, so that they can easily be extended in subclasses
without interference.)

Then, to display a browsing chunk, call
display_browse with parameters appropriate to what you're browsing.
Named arguments are presumed.  The one parameter that'd required
at this level is "chunksize", which specifies how many items to
display in a browse view.   There are also optional "key" and
"index" parameters that specify where in the browse index one should
start displaying.  If index is defined, and what's at that index is
consistent with they key, that's used as the starting point; otherwise,
browsing starts from the first item macthing the key, or something
close by.

 For example, if you call

  $success = $browser->display_browse(chunksize=>25, key=>"Citizen");

you should see 25 items in the browse list, starting from the
item beginning with "Citizen" (or something nearby).  The key
is something that could be entered by a user to browse; it's
the responsibility of the appropriate browser implementation to
normalize it however is appropriate to the application (e.g.
casting to lowercase, removing initial articles
and extraneous punctuation, etc.)  This is generally done in the
find_right_slot method, described further below.

 Or, if you call

  $success = $browser->display_browse(chunksize=>20, index=>1000, key=>"A");

you will see 20 items starting at the item in index slot 1000, so long
as that starts with "A".  (If it doesn't, you may be taken somewhere
else, probably to the start of the A's in this case.)  Addressing by index
can be faster and more precise than addressing by key, and allows one to
navigate through multiple items that have the same key.  Having a key
given as a backup means that the link will continue to go somewhere
reasonable if for some reason the index is regenerated (and keyed items
get moved to different slot nmubers) before ths link displayed.
(This avoids the problem in many library catalogs, including Voyager's,
where stale links, or even links that have outlived a session, make
the browsing systeem throw up its hands.)

Browser assumes that the entries you're browsing are in an index
ordered by slot number.  If there are n entries being browsed, the slot
numbers run contiguously from 0 to n-1.

=head1 REQUIRED SUBCLASS FUNCTIONS

As Browser is currently implemented, you will need to implement
at least the following virtual functions in your subclass:

  ($slot, $errormsg) = $browser->find_right_slot(%params);

This returns a pair.  The first element is the number of the first slot
in the browse ordering that matches your parameters, or a nearby slot
if no such slot qualifies.  The second element is a diagnostic string
that explains the situation if something goes wrong (e. g. there's
no slot matching the parameters.)  This can then be printed to inform
the user of what happened.  If everything went smoothly, this
element will usually be false.  The usual parameters to this method
are key and/or index, and are used as described above.

  $htmlstuff         = $browser->get_item_display(index=>$slot);

The returns an HTML snippet that displays the item whose slot number is $slot.

  $number = $browser->get_index_size();

This returns the number of slots in the index.

These two functions can in theory be omitted if the subclass overrides
the default implementation of display_browse() so as not to use them.
But they're pretty basic capabilities that you'll probably need
in a browser anyway.

=head1 OPTIONAL SUBCLASS FUNCTIONS

The following functions are not strictly required to be implemented
(they have stub implementations in this class that will do in a pinch).
Certain aspects of the browser functionality, however, will not be
available if some of them are not overridden.

  $name = $browser->items_name();

Returns a string that names what is being browsed.  If not overridden,
returns "Items".  Subclasses might return other things like "Authors",
"Titles", etc.  This is assumed to be pastable into an HTML page.

  $htmlstuff = $browser->range_note(startname=>$startname, endname=>$endname);

Returns a snippet of HTML that displays a note after the description
of the range being browsed, usually giving additional browsing options.
There are two optional named arguments, startname and endname, that
can be given the names of the items at the start and end of the range.
(These can be useful if the note includes a link based on the range
currently being viewed.)

Examples of such snippets on The Online Books Page include options
in the author browsing to show or hide titles for the current range,
or an option in the call number browsing to display a summary of the
call number range over which one is currently browsing.  If you don't
have any special options in mind for your browse, the default
implementation simply omits any such note.

  $name      = $browser->get_item_name(index=>$slot);

Displays the name of the item at slot number $slot.  Needed if you
want to display a summary of the range you're browsing (which you
probably do).

  $url       = $browser->get_query_url(index=>$slot);

Returns the URL to be used for browsing a range starting at slot
number slot.  (Subclasses can also define other ways of specifying
the range, using different named parameters).  Needed for "previous"
and "next" links, and for other navigational features like the jump bar.

  $htmlstuff = $browser->quick_picks();

Returns a snippet of HTML that gives additional navigation options
in between the "previous" and "next" navigation options.
One common option here is an alphebetic link list, or links
to major categories, etc.

  $htmlstuff = $browser->jump_form();

Returns a snippet of HTML that gives a form for users entering
a location to jump to.  For example, in The Online Books Page this
is used to generate an entry box where users can type prefixes
that they can skip directly to (e.g. type in "shake" to get
close to Shakespeare.)

  $htmlstuff = $browser->start_list();
  $htmlstuff = $browser->end_list();
  $htmlstuff = $browser->early_end_marker();


Returns snippets of HTML used at the start of the list, the end
of the list, and if the list ends early, respectively.  Note that
if early_end_marker() is invoked, end_list() is still invoked after it.
Default is empty strings, but most subclasses will probably put
code for opening lists or tables here as appropriate.

  $htmlstuff = $browser->item_in_list(string=>$string, index=>$slot);

Returns a snippet of HTML placing the string given in the string parameter
in whatever HTML formatting is appropriate for the browser.  Depending
on the formatting, for instance, this might be a list item element,
or a table row element, in some particular style.  You can also feed
this routine other optional arguments.  The slot argument if used
is the slot number of the item.  In the Online Books Page call number
browse, the slot nmuber is used to generate within-list headers, for
instance.  Other browsers might use it to show list nmubering, if desired.

=head1 AUTHOR INFORMATION

This module was written by John Mark Ockerbloom.  Address
bug reports and comments to: ockerblo@pobox.upenn.edu.

=cut End of documentation.
