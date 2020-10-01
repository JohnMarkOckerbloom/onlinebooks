package OLBP::PendingSerials;
use OLBP::SubmissionPool;

my $bfdir      = "backfile";

# is_pending returns true if:
#   an ISSN was passed in and there's a match in the pool
#   or if no ISSN was passed in, but a title was, and there's a pool match
#   Otherwise, it returns false (including when there would have been 
#     a title match but an ISSN was passed in with no match.  We expect
#     this will be most useful to find ISSN-less matches while avoiding
#     false positives

sub is_pending {
  my ($self, %params) = @_;
  my $issn = $params{issn};
  my $title = $params{title};
  if ($issn) {
     return $self->{issns}->{$issn};
  }
  if ($title) {
     return $self->{titles}->{$title};
  }
  return 0;
}

sub _initialize_pending {
  my ($self, %params) = @_;
  my $pool = $self->{pool};
  my $filehash = $pool->get_files();
  return if (!$filehash);
  my @ids = keys %{$filehash};
  foreach my $id (@ids) {
    my $content = $filehash->{$id};
    if ($content) {
      my @lines = split /\n/, $content;
      foreach my $line (@lines) {
        if ($line =~ /ISSN\s+(\S*)/) {
          $self->{issns}->{$1} = 1;
        } elsif ($line =~ /TITLE\s+(.*)/) {
          $self->{titles}->{$1} = 1;
        }
      }
    }
  }
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{issns} = {};
  $self->{titles} = {};
  $self->{pool} = new OLBP::SubmissionPool(name=>$bfdir, dir=>$params{dir});
  $self->_initialize_pending();
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


