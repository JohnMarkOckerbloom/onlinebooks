package OLBP::RecordStore;
use strict;

sub get_record {
  my ($self, %params) = @_;
  my $id = $params{id};
  my $str;

  return undef if (!$id);
  if ($id =~ /^olbp/ || $id =~ /^_/) {
    $str = $self->{curated}->get_value(key=>$id);
  } else {
    my $offset;
    if ($id =~ /^\d/) {
      $offset = int($id);
    } else {
      $offset = $self->{extended}->get_value(key=>$id);
    }
    return 0 if (!int($offset));
    if (!$self->{exopen}) {
      open EXRECS, "< $self->{exname}" or return 0;
      $self->{exopen} = 1;
    }
    if (!(seek EXRECS, $offset, 0)) {
      return 0;
    }
    my $line;
    while ($line = <EXRECS>) {
      last if (!($line =~ /\S/));
      $str .= $line;
    }
  }
  if ($str) {
    return new OLBP::BookRecord(string=>$str);
  }
  return undef;
}

sub _initialize {
  my ($self, %params) = @_;
  my $dir = $params{dir};
  $self->{datadir} = $dir;
  my $chname = $dir . "indexes/records.hsh";
  $self->{curated} = new OLBP::Hash(name=>"records",
                                    filename=>$chname, cache=>1);
  my $exname = $dir . "exindexes/recpos.hsh";
  $self->{extended} = new OLBP::Hash(name=>"recpos",
                                    filename=>$exname, cache=>1);
  $self->{exopen} = 0;
  $self->{exname} = $dir . "exindexes/recordcontent.dat";
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


