package OLBP::GetAvailability;

use lib "/websites/OnlineBooks/nonpublic/lib";
use OLBP;
use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(get_availability_status);

my $prefix = "http://onlinebooks.library.upenn.edu/webbin/book/lookupid?key=";

my $hashes = {};

my $q;

sub gethashval {
  my ($name, $key) = @_;

  return undef if (!$name);
  my $hash = $hashes->{$name};
  if (!$hash) {
    my $fname = OLBP::hashfilename($name);
    $hash = new OLBP::Hash(name=>$name, filename=>$fname, cache=>1);
    return undef if (!$hash);
    $hashes->{name} = $hash;
  }
  return $hash->get_value(key=>$key);
}

sub book_id {
  my $id = shift;
  if ($id =~ /(.*)-/) {
    $id = $1;
  }
  return $id;
}

sub ref_number {
  my $id = shift;
  if ($id =~ /-i(\d*)/) {
    return $1 - 1;
  }
  return 0;
}

sub get_availability_status {
  my ($idtype, $idreturn, @ids) = @_;
  my $avail = {};
  foreach my $id (@ids) {
    my $bookid = book_id($id);
    if ($bookid ne $id) {
      $avail->{$id}->{bid} = $bookid;
    }
    my $str = gethashval("records", $bookid);
    my $br = new OLBP::BookRecord(string=>$str);
    if ($str && $br) {
      my @refs = $br->get_refs();
      if (scalar(@refs)) {
        my $refno = ref_number($id);
        if ($refno >= scalar(@refs)) {
          $avail->{$id}->{status} = $ILSDI::AVAILABLE_NO;
          $avail->{$id}->{msg} = "No link in that position";
        } else {
          $avail->{$id}->{status} = $ILSDI::AVAILABLE_YES;
          if (($id eq $bookid) && scalar(@refs) > 1) {
            $avail->{$id}->{msg} = "multiple links";
            $avail->{$id}->{location} = $prefix . $id;
          } else {
            my $ref = $refs[$refno];
            if ($ref =~ /(\S+)\s+(.*)/) {
              $avail->{$id}->{msg} = $2;
              $avail->{$id}->{location} = $1;
            }
          }
       }
      } else {
        $avail->{$id}->{status} = $ILSDI::AVAILABLE_NO;
        $avail->{$id}->{msg} = $br->get_note();
      }
    } else {
      $avail->{$id}->{status} = $ILSDI::AVAILABLE_UNKNOWN;
      $avail->{$id}->{msg} = "Error: could not retrieve availability for this ID";
    }
  }
  return $avail;
}

1;
