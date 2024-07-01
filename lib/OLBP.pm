package OLBP;
use strict;
use utf8;

use OLBP::Hash;
use OLBP::BookRecord;
use OLBP::Name;
use OLBP::Index;
use OLBP::Browser;
use OLBP::AuthorBrowser;
use OLBP::AuthorTitleBrowser;
use OLBP::CallBrowser;
use OLBP::TitleBrowser;
use OLBP::SubjectBrowser;
use OLBP::Entities;

$OLBP::currentyear = 2024;

$OLBP::dbdir =  "/websites/OnlineBooks/nonpublic/bookdb/";

my $idxdir      = $OLBP::dbdir . "indexes/";
 
my $authoraddr = "onlinebooks\@pobox.upenn.edu";

$OLBP::serverurl = "https://onlinebooks.library.upenn.edu/";
my $booksurl  = $OLBP::serverurl;
my $cgiurl    = $OLBP::serverurl . "webbin/";
$OLBP::styleurl  = $booksurl . "olbp.css";

$OLBP::homepage  = $booksurl;
my $listspage = $booksurl . "lists.html";
my $newspage = $booksurl . "news.html";
my $featurespage = $booksurl . "features.html";
my $archivespage = $booksurl . "archives.html";
my $insidepage = $booksurl . "inside.html";
my $licensepage = $booksurl . "licenses.html";

$OLBP::searchpage = $booksurl . "search.html";
$OLBP::stablepage = $booksurl . "stable.html";
my $newpage = $booksurl . "new.html";
$OLBP::authorspage = $booksurl . "authors.html";
$OLBP::titlespage = $booksurl . "titles.html";
$OLBP::calloverview = $booksurl . "subjects.html";
my $serialspage = $booksurl . "serials.html";
$OLBP::rssfeed = $booksurl . "newrss.xml";

$OLBP::suggestpage = $booksurl . "suggest.html";
$OLBP::readerhelp  = $booksurl . "readers.html";

my $smalllogo = $booksurl . "olbpsm.gif";
my $logowidth  = 381;
my $logoheight =  30;
$OLBP::infologo  = $booksurl . "info.gif";
$OLBP::xinfologo  = $booksurl . "infouc.gif";

$OLBP::badlinkurl     = $cgiurl . "olbpcontact?type=badlink";
$OLBP::scripturl      = $cgiurl . $OLBP::SCRIPTNAME;
$OLBP::ncalloverview  = $OLBP::scripturl . "/callover";
$OLBP::suggestformurl = $cgiurl . "suggest";
$OLBP::seealsourl     = $cgiurl . "ftl";

# $OLBP::bodystart = "<body bgcolor=\"#ffffff\" text=\"#000000\"" .
#                    " link=\"#00188c\" vlink=\"#661855\" alink=\"#ff0000\">\n" .
#                    "<center><a href=\"$OLBP::homepage\">" .
#                    "<img border=0 src=\"$smalllogo\"" .
#                    " width=\"$logowidth\" height=\"$logoheight\"" .
#                    " alt=\"The Online Books Page\"></a></center>\n";

$OLBP::bodystart = qq!<body>
<header>
<h1><a href="$OLBP::homepage" class="logolink">The Online Books Page</a></h1>
</header>
!;

my $centerstyle = "style=\"text-align:center\"";

my $endnavigation = "<p $centerstyle>\n" .
                 "<a href=\"$listspage\">Books</a> -- " .
                 "<a href=\"$newspage\">News</a> -- " .
                 "<a href=\"$featurespage\">Features</a> -- " .
                 "<a href=\"$archivespage\">Archives</a> -- " .
                 "<a href=\"$insidepage\">The Inside Story</a></p>\n";

my $credits = "<p $centerstyle><i>Edited by " .
                 "John Mark Ockerbloom  (" . emailobscure($authoraddr) . ")";

my $license = "<a href=\"$licensepage\">OBP copyrights and licenses</a>.";

$OLBP::bodyend = $endnavigation . $credits . "<br>" . $license . 
                 "</i></p></body></html>\n";

$OLBP::cc0bodyend = $endnavigation . $credits . "<br>"   .
          "Data for this curated collection listing is CC0. See " . $license .
                 "</i></p></body></html>\n";

$OLBP::copyrcc0bodyend = $credits . "<br>"   .
          "Data on this copyright information page is CC0. See " . $license .
                 "</i></p></body></html>\n";


$OLBP::authorsortkeylimit = 80;
$OLBP::titlesortkeylimit  = 100;
$OLBP::atsortkeylimit     = 150;

$OLBP::subjectsortkeylimit= 100;

$OLBP::authortitlesep = "\x01";

$OLBP::callrangefile = $OLBP::dbdir . "subjectfile";

$OLBP::wpstub = "https://en.wikipedia.org/wiki/";

# emailobscure turns the characters before and after the @ into
# numeric HTML entities.  (It only does this if they're alphanumeric,
# so it doesn't mess up things that are already entities.)
# This seems to thwart most email harvesters that spammers use,
# while still keeping the address looking the same in Web browsers.

sub emailobscure {
  my $str = shift;
  $str =~ s/(\w)\@/"&#".ord($1).";\@"/e;
  $str =~ s/\@(\w)/"\@&#".ord($1).";"/e;
  return $str;
}

sub html_encode {
  my $str = shift;
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  return $str;
}

sub url_char_encode {
  my $char = shift;
  if (ord($char) < 128) {
     return "%".sprintf("%02x", ord($char));
  }
  my $str = $char;
  utf8::encode($str);
  $str =~ s/(.)/"%".sprintf("%02x", ord($1))/eg;
  return $str;
}

sub url_encode {
  my $str = shift;
  $str =~ s/([^a-zA-Z_0-9])/&url_char_encode($1)/eg;
  $str =~ s/ /+/g;
  return $str;
}

my $DEFAULTSTOP = {"a" => 1, "an" =>1, "and" =>1, "are" =>1,
                   "by" =>1, "for"=>1, "if" =>1, "is" =>1, "it" =>1, 
                   "no" =>1, "not" =>1, 
                   "of" =>1, "or"=>1, "the"=>1, "was" =>1, "were"=>1,
                   "with"=>1};

# search_words:
# Returns a non-duplicated array of search words to use
# "string" parameter is string
# "markup" parameter is true if the array can include entity markup
# "stopwords" parameter is pointer to stop words to use (default DEFAULTSTOP)
# "hyphens" parameter:
#   default: keep them together
#   "join": remove hyphens and index the whole word
#   "split" split hypenated words ("hocus-pocus" becomes "hocus" and "pocus")
#   "both": use both join and split in search list

sub search_words {
  my (%params) = @_;
  my $str = $params{string};
  my $stopwords = $params{stopwords} || $DEFAULTSTOP;
  my $hyphenpolicy = $params{hyphens} || "keep";
  my $markup = $params{markup};
  my @array = split /\s+/, $str;
  my %words = ();
  foreach my $word (@array) {
    $word = lc($word);
    if ($word =~ /-/) {
      if ($hyphenpolicy eq "split" || $hyphenpolicy eq "both") {
        my @wordlets = split /\-/, $word;
        foreach my $wordlet (@wordlets) {
          &_addtowords(\%words, $wordlet, $markup, $stopwords);
        }
      }
      if ($hyphenpolicy eq "join" || $hyphenpolicy eq "both") {
        $word =~ s/-//g;
        &_addtowords(\%words, $word, $markup, $stopwords);
      }
      if (!$hyphenpolicy) {
        &_addtowords(\%words, $word, $markup, $stopwords);
      }
    } else {
      &_addtowords(\%words, $word, $markup, $stopwords);
    }
  }
  return keys %words;
}

sub _addtowords {
  my ($hashref, $word, $markup, $stopwords) = @_;
  if ($markup) {
    $word = OLBP::Entities::normalize_entities($word);
  }
  # now strip out all punctuation and the like
  $word =~ s/\W//g;
  if ($word && !$stopwords->{$word}) {
    $hashref->{$word} = 1;
  }
}

sub result_tips {
  return choicelist(0, ("Help with reading books" => $OLBP::readerhelp,
                        "Report a bad link" => $OLBP::badlinkurl,
                        "Suggest a new listing" => $OLBP::suggestpage));
}

sub choicelist {
  my ($nolink, @choices) = @_;
  my @choicedisplay;
  if (!scalar(@choices)) {
     @choices = ("Home"            => $OLBP::homepage,
                 "Search"          => $OLBP::searchpage,
                 "New Listings"    => $newpage,
                 "Authors"         => $OLBP::authorspage,
                 "Titles"          => $OLBP::titlespage,
                 "Subjects"        => $OLBP::calloverview,
                 "Serials"         => $serialspage);
  }

  for (my $i = 0; $choices[$i]; $i += 2) {
    if ($choices[$i] eq $nolink) {
      push @choicedisplay, "<b>$choices[$i]</b>";
    } else {
      push @choicedisplay, "<a href=\"$choices[$i+1]\">$choices[$i]</a>";
    }
  }
  return "<p $centerstyle>" . join(" -- ", @choicedisplay) . "</p>\n";
}


sub hashfilename { return ($_[1] || $idxdir) . $_[0] . ".hsh";}
sub indexfilename { return ($_[1] || $idxdir) . $_[0] . ".idx";}
sub authorentriesfile { return ($_[0] || $idxdir) . "authorentries.dat";}
sub subjectentriesfile { return ($_[0] || $idxdir) . "subjectentries.dat";}

1;
