package OLBP::OAI;
use strict;
use OLBP::Entities;

my %ROLECODE = ( "AUTHOR"=> "aut", "EDITOR"=> "edt", "CONTRIBUTOR"=> "ctb",
                 "ILLUSTRATOR"=> "ill", "TRANSLATOR"=> "trl");

sub _numeric_text_tag {
  my ($label, $value) = @_;
  return "<$label>" . OLBP::Entities::numeric_entities($value) . "</$label>";
}

my $GENERAL_ACCESS = 
"The editor of The Online Books Page believes that free access to this item".
" for personal, noncommercial use is permitted in the United States" .
" of America, and in the country of the site providing this item. " .
" Other use and reproduction rights may also apply,  depending on the text" .
" and its provider.";

my $NONUS_ACCESS = 
"The editor of The Online Books Page believes that this item is in the".
" public domain in the country of the site providing this item, but".
" that it is likely to still be copyrighted, and access restricted,".
" in the United States of America.";

# Returns an OAI-compliant Dublin Core record
# If "celebration" parameter is set, we're generating for the Celebration
# and we assume we're only being fed Celebration records
# and the celebration value should be that site's base URL

sub _celebration_access {
  my $womenurl = shift;
  return 
   "Personal, noncommercial use of this item is permitted in the ".
   "United States of America.  Please see $womenurl ".
   "for other rights and restrictions that may apply to this resource.";
}

sub oai_dc {
  my ($self, %params) = @_;
  my $womenurl = $params{celebration};
  my $br = $params{record};
  my $str = "";
  my $title = $br->get_title();
  if ($title) {
    $str .= _numeric_text_tag("dc:title", $title) . "\n";
  }
  my @names = $br->get_names();
  my @roles = $br->get_roles();
  for (my $i = 0; $i < scalar(@names); $i++) {
    my $tag = "dc:contributor";
    if ($roles[$i] =~ /AUTHOR|EDITOR|TRANSLATOR|ILLUSTRATOR/) {
      $tag = "dc:creator";
    }
    $str .= _numeric_text_tag($tag, $names[$i]) . "\n";
  }
  my @subs = $br->get_subjects();
  foreach my $sub (@subs) {
    $str .= _numeric_text_tag("dc:subject", $sub) . "\n";
  }
  my $lccn = $br->get_lccn();
  if ($lccn) {
    $str .= "<dc:subject>$lccn</dc:subject>\n";
  }
  my @refs = $br->get_refs();
  foreach my $ref (@refs) {
    if ($ref =~ /(\S+)\s+(.*)/) {
      my $url = $1;
      my $formatnotes = $2;
      if (!$womenurl || $womenurl eq substr($url, 0, length($womenurl))) {
            $str .= "<dc:identifier>" . OLBP::html_encode($url)
                  . "</dc:identifier>\n";
         if ($formatnotes =~ /HTML/) {
           $str .= "<dc:format>text/html</dc:format>\n";
         }
         if ($formatnotes =~ /PDF/) {
           $str .= "<dc:format>application/pdf</dc:format>\n";
         }
         if ($formatnotes =~ /text/) {
           $str .= "<dc:format>text/plain</dc:format>\n";
         }
      }
    }
  }
  my $note = $br->get_note();
  if ($note) {
    $str .= _numeric_text_tag("dc:description", $note) . "\n";
    if ($note =~ /(.*): (.*), (\d\d\d\d)$/) {
      $str .= _numeric_text_tag("dc:publisher", $2) . "\n";
      $str .= "<dc:date>$3</dc:date>\n";
    }
  }
  if ($womenurl) {
    $str .= "<dc:publisher>A Celebration of Women Writers</dc:publisher>\n";
  }
  my $date = $br->get_iso_date();
  if ($date) {
    $str .= "<dc:date>$date</dc:date>";
  }
  $str .= "<dc:rights>";
  if ($womenurl && $refs[0] =~ /$womenurl/) {
    $str .= _celebration_access($womenurl);
  } elsif (scalar($br->get_nonus_refs())) {
    $str .= $NONUS_ACCESS;
  } else {
    $str .= $GENERAL_ACCESS;
  }
  $str .= "</dc:rights>\n";
  $str .= "<dc:type>Text</dc:type>\n";
  return $str;
}

sub _english {
  my $code = "eng";
  my $name = "English";
  return "<languageTerm type=\"code\" authority=\"iso639-2b\">$code" .
         "</languageTerm><languageTerm type=\"text\">$name</languageTerm>";
}

# Returns an OAI-compliant MODS record as close to the Aquifer standard
#  as we can manage.
# If "celebration" parameter is set, we're generating for the Celebration
# and we assume we're only being fed Celebration records
# and the celebration value should be that site's base URL

sub oai_mods {
  my ($self, %params) = @_;
  my $womenurl = $params{celebration};
  my $br = $params{record};
  my $str = "";
  my $title = $br->get_title();
  if ($title) {
    $str .= "<titleInfo>";
    $str .= _numeric_text_tag("title", $title);
    $str .= "</titleInfo>\n";
  }
  my @ot = $br->get_other_titles();
  foreach my $t (@ot) {
    $str .= "<titleInfo type=\"alternative\">";
    $str .= _numeric_text_tag("title", $t);
    $str .= "</titleInfo>\n";
  }
  my @names = $br->get_names();
  my @roles = $br->get_roles();
  my @refs = $br->get_refs();
  my $note = $br->get_note();
  for (my $i = 0; $i < scalar(@names); $i++) {
    my $name = $names[$i];
    my $role = $roles[$i];
    $str .= "<name>";
    $str .= _numeric_text_tag("namePart", $name) . "\n";
    if ($ROLECODE{$role}) {
      $str .= "<role><roleTerm type=\"code\" authority=\"marcrelator\">";
      $str .= $ROLECODE{$role} . "</roleTerm>\n";
      $str .= "<roleTerm type=\"text\" authority=\"marcrelator\">";
      $str .= ucfirst(lc($role)) . "</roleTerm>";
      $str .= "</role>\n";
    }
    $str .= "</name>\n";
  }
  $str .= _numeric_text_tag("typeOfResource", "text") . "\n";

  $str .= "<originInfo>";
  my $date = "";
  my $t = "dateOther";
  my $q = "";
  if ($note && $note =~ /(\d\d\d\d)$/) {
    if ($1 > 1000 && $1 < 2100) {
      $date = $1;
      $t = "dateIssued";
      if ($note =~ /c(\d\d\d\d)$/) {
        $t = "copyrightDate";
      }
    }
  }
  if (!$date) {
    # if all else fails, use the accession date
    # most book records have dates, but some pre-1994 ones don't
    $q = "questionable"; 
    $date = $br->get_iso_date() || "1994";
  }
  $str .= "<$t keyDate=\"yes\" encoding=\"w3cdtf\"";
  if ($q) {
    $str .= " qualifier=\"$q\"";
  }
  $str .= ">$date</$t>";
  $str .= "</originInfo>\n";
  $str .= "<language>" . _english() . "</language>\n";
  $str .= "<physicalDescription>";
  my %fhash = ();
  foreach my $ref (@refs) {
    if ($ref =~ /PDF/) {
      $fhash{"application/pdf"} = 1;
    }
    if ($ref =~ /HTML/) {
      $fhash{"text/html"} = 1;
    }
    if ($ref =~ /text/) {
      $fhash{"text/plain"} = 1;
    }
  }
  my @formats = keys %fhash;
  if (!scalar(@formats)) {
    push @formats, "application/octet-stream";
  }
  foreach my $fmt (@formats) {
     $str .= _numeric_text_tag("internetMediaType", $fmt) . "\n";
  }
  $t = "born";
  if (int($date) && int($date) < 1970 && 
      (!($note =~ /commentary/)) &&
      (!($refs[0] =~ /commentary/))) {
    $t = "reformatted";
  }
  $str .= _numeric_text_tag("digitalOrigin", "$t digital") . "\n";
  $str .= "</physicalDescription>\n";
  # we'll use note if it'sanytihng more than a year
  if ($note && $note =~ /[a-z]/) {
    $str .= _numeric_text_tag("note", $note) . "\n";
  }
  my @subs = $br->get_subjects();
  foreach my $sub (@subs) {
    $str .= "<subject authority=\"lcsh\">";
    $str .= _numeric_text_tag("topic", $sub);
    $str .= "</subject>\n";
  }
  my $lccn = $br->get_lccn();
  if ($lccn) {
    $str .= "<classification authority=\"lcc\">";
    $str .= OLBP::Entities::numeric_entities($lccn);
    $str .= "</classification>\n";
  }
  # identifier currently not used, but could be reused from location
  $str .= "<location>";
  my $access = "object in context";
  my $slink = $br->get_stable_link();
  if (!$slink && !$womenurl) {
    $access = "raw object";
  }
  my $url = $OLBP::homepage;
  if ($womenurl && $refs[0] =~ /$womenurl/) {
    $url = $refs[0];
    $url =~ s/\s+.*//;    # remove reference commentary
  } elsif ($slink) {
    $url = $slink;
  } elsif ($refs[0]) {
    $str .= $refs[0];
  }
  $str .= "<url usage=\"primary display\" access=\"$access\">";
  $str .= OLBP::Entities::numeric_entities($url);
  $str .= "</url></location>\n";
  $str .= "<accessCondition type=\"useAndReproduction\">";
  if ($womenurl && $refs[0] =~ /$womenurl/) {
    $str .= _celebration_access($womenurl);
  } elsif (scalar($br->get_nonus_refs())) {
    $str .= $NONUS_ACCESS;
  } else {
    $str .= $GENERAL_ACCESS;
  }
  $str .= "</accessCondition>\n";
  $str .= "<recordInfo>\n";
  $str .= _numeric_text_tag("recordOrigin", 
   "MODS auto-converted from a simple Online Books Page metadata record. " .
   " For details, see https://onlinebooks.library.upenn.edu/mods.html");
  $str .= "<languageOfCataloging>" . _english() . "</languageOfCataloging>";
  $str .= "</recordInfo>\n";
  return $str;
}

# oai_dlfexpanded attempts to return an expanded record in 
# the DLF ILS discovery interface format

my $MODSOPEN = qq! 
<mods
    xmlns="http://www.loc.gov/mods/v3"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.loc.gov/mods/v3
                    http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
!;

my $MODSCLOSE = "\n</mods>\n";

sub oai_dlfexpanded {
  my ($self, %params) = @_;
  my $bibrecstr = $self->oai_mods(%params);
  my $br = $params{record};
  return "" if (!$br || !$bibrecstr);
  my $id = $br->get_id();
  my $str .= "<dlf:bibliographic id=\"$id\">\n";
  $str .= $MODSOPEN . $bibrecstr . $MODSCLOSE;
  $str .= "</dlf:bibliographic>\n";
  my @refarray = $br->get_refs();
  if (scalar(@refarray)) {
    $str .= "<dlf:items>\n";
    for (my $i = 0; $refarray[$i]; $i++) {
      my $itemid = $id . "-i" . ($i+1);
      $str .= "<dlf:item id=\"$itemid\" />\n";
    }
    $str .= "</dlf:items>\n";
  }
  return $str;
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


