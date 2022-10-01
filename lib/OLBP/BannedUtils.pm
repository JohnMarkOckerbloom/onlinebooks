package OLBP::BannedUtils;
use OLBP;
use OLBP::BannedSet;
use OLBP::BannedCitation;
use JSON;

my $serverurl    = "https://onlinebooks.library.upenn.edu/";
my $cgiprefix    = $serverurl . "webbin/";
my $bannedscript = $cgiprefix . "banned";

my $bandir  = $OLBP::dbdir . "banned/";
my $workdir = $bandir . "works/";
my $catdir  = $bandir . "categories/";
my $citedir = $bandir . "bib/";

my $jsonparser;

sub _expand_macro {
  my ($command, $arg) = @_;
  if ($command eq "ln") {
    my ($url, $text) = split '\|', $arg;
    return qq!<a href="$url">$text</a>!;
  }
  if ($command eq "wk") {
    my ($url, $text) = split '\|', $arg;
    $url = $bannedscript . "/work/$url";
    return qq!<a href="$url">$text</a>!;
  }
  if ($command eq "info") {
    my ($url, $text) = split '\|', $arg;
    $url = $bannedscript . "/info/$url";
    return qq!<a href="$url">$text</a>!;
  }
  if ($command eq "cat") {
    my ($url, $text) = split '\|', $arg;
    if (!$text) {
      $url = $arg;
      $text = $arg;
    }
    $url = $bannedscript . "/category/$url";
    return qq!<a href="$url">$text</a>!;
  }
  if ($command eq "pt") {
    # Page title has already been shown in the calling routine
    return "";
  }
  if ($command eq "bib") {
    my $citation = new OLBP::BannedCitation(dir=>$citedir, id=>$arg);
    return $citation->display_html();
  }
  if ($command eq "row") {
    my $cattable = "$catdir$arg.tsv";
    return "Category $arg not found" if (! -e $cattable);
    my $set = new OLBP::BannedSet(dir=>$catdir, id=>$arg, workdir=>$workdir);
    my $str = $set->display_random_covers();
    my $url = $bannedscript . "/category/$arg";
    my $text = "full list" . ($arg eq "all" ? "" : " for this category");
    $str .= qq!
     <p class="coverrow-caption">See more in our <a href="$url">$text</a>.</p>!;
    return $str;
  }
  return "(unknown macro: $command with arg: $arg)";
}

sub expand_html_template {
  my $str = shift;
  $str =~ s/\{([a-z]*):([^\}]*)\}/_expand_macro($1, $2)/ge;
  return $str;
}

sub get_json_parser {
  if (!$jsonparser) {
    $jsonparser = JSON->new->allow_nonref;
  }
  return $jsonparser;
}

1;

