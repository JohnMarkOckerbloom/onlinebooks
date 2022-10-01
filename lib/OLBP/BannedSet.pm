package OLBP::BannedSet;
use strict;
use OLBP;
use OLBP::BannedWork;
use OLBP::BannedUtils;
use JSON;

sub _readworksfile {
  my ($self, $path) = @_;
  my $lines;
  open my $fh, "< $path" or return undef;
  while (my $line = <$fh>) {
    chop $line;
    push @{$lines}, $line;
  }
  binmode $fh, ":utf8";
  close $fh;
  return $lines;
}

sub _readjsonfile {
  my ($self, $path) = @_;
  my $str;
  open my $fh, "< $path" or return undef;
  binmode $fh, ":utf8";
  while (<$fh>) {
    $str .= $_;
  }
  close $fh;
  return $self->{parser}->decode($str);
}

sub _get_json {
  my ($self, %params) = @_;
  if (!$self->{json}) {
    my $path = $self->{dir} . $self->{id} . ".json";
    $self->{json} = $self->_readjsonfile($path);
  }
  return $self->{json};
}

sub get_works {
  my ($self, %params) = @_;
  my $fname = $params{filename};
  $fname =~ s/[^A-Za-z0-9\-]//g;     # sanitize input
  my $path = $self->{dir} . $fname . ".tsv";
  return $self->_readworksfile($path);
}

sub tsv_table {
  my ($self, %params) = @_;
  my $str = "";
  if ($self->{works}) {
    foreach my $work (@{$self->{works}}) {
      my $id = $work->get_id();
      my $title = $work->get_title();
      my $authorstr = $work->get_author_summary();
      my $pyear = $work->get_publication_year();
      my $iyear = $work->get_recent_censorship_year();
      $str .= join("\t", $id, $title, $authorstr, $pyear, $iyear);
      $str .= "\n";
    }
  }
  return $str;
}

sub write_table {
  my ($self, %params) = @_;
  my $path = $self->{dir} . $self->{id} . ".tsv";
  my $table = $self->tsv_table();
  open OUT, "> $path";
  binmode OUT, ":utf8";
  print OUT $table;
  close OUT;
}

sub _description_display_html {
  my ($self, $json) = @_;
  my $str = qq!<div class="category-description">!;
  if ($json) {
    my $html = $json->{"introduction"};
    $html = OLBP::BannedUtils::expand_html_template($html);
    $str .= "<p>$html</p>";
  }
  $str .= "</div>\n";
  return $str;
}


my @columns =
("Title"=> 30, "Author"=>30, "First published"=>20, "Recent incident"=> 15);

sub _table_header {
  my $str = "<thead><tr>\n";
  while (my $name = shift @columns) {
    my $width = shift @columns;
    $str .= qq!<th style="width: $width%">$name</th>!;
  }
  $str .= "</tr></thead>\n";
  return $str;
}

sub _table_cell {
  my ($str, $uri) = @_;
  $str = OLBP::html_encode($str);
  if ($uri) {
    $str = qq!<td><a href="$uri">$str</a></td>\n!;
  } else {
    $str = "<td>$str</td>\n";
  }
  return $str;
}

sub _table_row {
  my ($self, $workline) = @_;
  my ($id, $title, $authorstr, $pyear, $iyear) = split '\t', $workline;
  my $uri = "/webbin/banned/work/$id";
  my $str = "<tr>";
  $str .= _table_cell($title, $uri);
  $str .= _table_cell($authorstr);
  $str .= _table_cell($pyear);
  $str .= _table_cell($iyear);
  $str .= "</tr>";
  return $str;
}


sub _table_display_html {
  my ($self) = @_;
  my $str = qq!<div class="category-table-div">!;
  $str .= qq!<table class="ban-category-table">\n!;
  $str .= _table_header();
  $str .= "<tbody>\n";
  my $worklines = $self->{worklines};
  if ($worklines) {
    foreach my $workline (@{$worklines}) {
      $str .= $self->_table_row($workline);
    }
  }
  $str .= "</tbody>\n";
  $str .= "</table>\n";
  $str .= "</div>\n";
  return $str;
}

sub _pick_random_worklines {
  my ($worklines, $covercount) = @_;
  my $workcount = scalar(@{$worklines});
  my %randomhash = ();
  if (!$workcount) {
    return ();
  }
  if ($workcount <= $covercount) {
    return (0 .. ($workcount-1));
  }
  while ($covercount > 0) {
    my $pick = int(rand($workcount));
    # $pick = "goshdarn $pick out of $workcount";
    if (!$randomhash{$pick}) {
      $randomhash{$pick} = 1;
      $covercount -= 1;
    }
  }
  return keys %randomhash;
}

sub _cover_display_html {
  my ($self, $workline) = @_;
  my ($id, $title, $authorstr, $pyear, $iyear) = split '\t', $workline;
  my $work = new OLBP::BannedWork(dir=>$self->{workdir}, id=>$id);
  return $work->cover_display_html(link=>1, brief=>1);
}

sub _cover_row_display_html {
  my ($self, $worklines, @indexes) = @_;
  my $str = qq!<nav class="nav_horizontal"><ul class="nodot">\n!;
  foreach my $index (@indexes) {
    $str .= qq!<li class="rowcover">! 
         . $self->_cover_display_html($worklines->[$index])
         . qq!</li>\n!;
  }
  $str .= qq!</ul></nav>\n!;
  return $str
}

sub display_random_covers {
  my ($self, %params) = @_;
  my $covercount = 4;
  my $worklines = $self->{worklines};
  return "" if (!$worklines);
  my @indexes = _pick_random_worklines($worklines, $covercount);
  return $self->_cover_row_display_html($worklines, @indexes);
}

sub display_html {
  my ($self, %params) = @_;
  my $str = "";
  my $json = $self->_get_json();
  $str .= $self->_description_display_html($json);
  $str .= $self->_table_display_html();
  return $str;
}

sub get_title {
  my ($self, %params) = @_;
  my $str = "";
  my $json = $self->_get_json();
  if ($json) {
    return $json->{"title"};
  }
  return $self->{id};
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{dir} = $params{dir};
  $self->{workdir} = $params{workdir};
  $self->{id} = $params{id};
  $self->{works} = $params{works};
  $self->{parser} = OLBP::BannedUtils::get_json_parser();
  if (!$self->{works}) {
    $self->{worklines} = $self->get_works(filename=>$self->{id});
  }
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;

