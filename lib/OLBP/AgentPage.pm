package OLBP::AgentPage;
use OLBP::Name;
use OLBP::RecordStore;

$OLBP::AgentPage::styleurl =
    "https://onlinebooks.library.upenn.edu/whopage.css";

my $extradir  = $OLBP::dbdir . "exindexes/";

sub _display_franklin {
print qq!
<a title="Joseph-Siffred Duplessis
, Public domain, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Joseph_Siffrein_Duplessis_-_Benjamin_Franklin_-_Google_Art_Project.jpg"><img height="120" alt="Joseph Siffrein Duplessis - Benjamin Franklin - Google Art Project" src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Joseph_Siffrein_Duplessis_-_Benjamin_Franklin_-_Google_Art_Project.jpg/256px-Joseph_Siffrein_Duplessis_-_Benjamin_Franklin_-_Google_Art_Project.jpg?20121003015254"></a>
!;
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

sub _display_banner {
  my ($self, $name, $informal) = @_;
  print qq!<div class="whobanner">!;
  print qq!<table><tr><td>!;
  print "<h2>$informal</h2>\n";
  my $naivename = OLBP::Name::naive($name);
  if ($naivename ne $informal) {
    print "<h3>($name)</h3>\n";
  }
  print qq!</td><td width="15%"></td><td>!;
  if ($informal =~ /Benjamin Franklin/) {
    _display_franklin();
  }
  print qq!</td></tr></table>!;
  print "</div>";
}

sub _get_string_from_file {
  my ($self, $name, $singleline) = @_;
  my $str;
  my $path = $self->{dir} . "/$name";
  open my $fh, "< $path" or return undef;
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
  return $self->{heading};
}

sub get_informal {
  my ($self) = @_;
  if (!$self->{informal}) {
    $self->{informal} = $self->_get_string_from_file("informal", 1);
  }
  return $self->{informal};
}

sub _print_lead {
  my ($str) = @_;
  $str =~ s!\'\'\'(.*)?\'\'\'!<b>$1</b>!g;
  $str =~ s!</b>\s*\(.*?\)!</b>!;          # remove parenthetical after boldname
  print "<p>$str</p>";
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

sub display {
  my ($self, %params) = @_;
  my $name = $self->get_heading();
  my $informal = $self->get_informal();
  my $desc = $self->_get_string_from_file("wplead");
  if (!$informal) {
    $informal = OLBP::Name::informal($name);
  }
  $self->_display_banner($name, $informal);
  print qq!<table><tr><td class="agentinfo">\n!;
  if ($desc) {
    _print_lead($desc);
  } else {
    print "Information goes here.";
  }
  my $akey = OLBP::BookRecord::sort_key_for_name($name);
  my $val = gethashval("authortitles", $akey);
  my $exval = gethashval("authortitles", $akey, $extradir);
  my $skey = OLBP::BookRecord::search_key_for_subject($name);
  my @subjectbooks = $self->{subbrowser}->get_books_with_subject(key=>$skey);
  print qq!</td><td class="separator">&nbsp;!;
  print qq!</td><td class="agentworks">!;
  if (scalar(@subjectbooks) && ($val || $exval)) {
    print qq!<p><a href="#booksabout">Books about $informal</a> -- 
                <a href="#booksby">Books by $informal</a></p>!;
  }
  if (scalar(@subjectbooks)) {
    # might need better way to get subs when nothing filed directly under name
    print "<p id=\"booksabout\"><strong>Books about $informal:</strong></p>";
    $self->{subbrowser}->show_books_under_subject(term=>$name, max=>50,
                                                  downonly=>1);
  }
  if ($val || $exval) {
    print "<p id=\"booksby\"><strong>Books by $informal:</strong><p>";
    $self->display_works(curatedbookvals=>$val, extendedbookvals=>$exval);
  }
  print "</td></tr></table>";
}

sub _initialize {
  my ($self, %params) = @_;
  $self->{id} = $params{id};
  $self->{dir} = $params{dir};
  $self->{subbrowser} = $params{subbrowser};
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;
