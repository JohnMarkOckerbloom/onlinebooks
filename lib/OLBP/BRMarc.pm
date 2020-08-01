use MARC::Record;
use MARC::File::XML;

sub _nonfiling_characters {
  my ($title, $note) = @_;
  if ($title =~ /^(A|An|The|Der|Das) /) {
    return length($1) + 1;
  }
  if ($note =~ /Spanish/ && $title =~ /^(Las|Los|El) /) {
    return length($1) + 1;
  }
  if ($note =~ /French/ && $title =~ /^(Le|La|Les) /) {
    return length($1) + 1;
  }
  if ($note =~ /French/ && $title =~ /^(L')/) {
    return length($1);
  }
  if ($note =~ /German/ && $title =~ /^(Die) /) {
    return length($1) + 1;
  }
  return 0;
}

sub makemarc {
  my ($self, %params) = @_;
  my $br = $params{record};
  my $marc = new MARC::Record();
  my $title = $br->get_title();
  my $note = $br->get_note();
  my $nonfiling = _nonfiling_characters($title, $note);
  my $field = new MARC::Field('245', '0', $nonfiling, 
                              'a' => $title);
  $marc->append_fields($field);

  return $marc;
}

sub makemarcxml {
  my ($self, %params) = @_;
  my $marc = makemarc(%params);
  my $xml = MARC::File::XML::record($marc);
  return $xml;
}

1;
