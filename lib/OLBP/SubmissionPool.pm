package OLBP::SubmissionPool;
use strict qw(vars subs);  # Can't use strict refs with our filehandles
use Fcntl qw (:DEFAULT :flock);

my $DATADIR = "/websites/OnlineBooks/nonpublic/submissions/";
# my $datadir = "/home/ockerblo/digital/nonpublic/submissions/";

sub _dirname {
  my ($self, %params) = @_;
  return "$self->{dir}/$self->{name}";
}

sub _get_new_filename {
  my ($self, %params) = @_;
  my $file = $self->_dirname() . "/.next";
  return 0 if (!sysopen(FH, $file, O_RDWR | O_CREAT));
  return 0 if (!flock(FH, LOCK_EX));
  my $idx = <FH>;
  if (!$idx) {              # First file should be 1
    $idx = 1;
  }
  seek (FH, 0, 0);
  print FH $idx + 1;
  truncate (FH, tell(FH));  # ensures there's nothing following this
  close FH or return 0;     # releases the lock
  return $self->_dirname() . "/$idx";
}

sub record_submission {
  my ($self, %params) = @_;
  my $str = $params{string};
  my $name = $self->_get_new_filename();
  return 0 if (!$name);
  open FH, "> $name" or return 0;
  print FH $str;
  close FH or return 0;
  return 1;
}

sub finish_submission {
  my ($self, %params) = @_;
  my $id = $params{id};
  my $olddir = $params{olddir} || ".old";
  if (!$id || $id != int($id)) {
    return 0;
  } 
  my $base = $self->_dirname();
  my $name1 = "$base/$id";
  my $name2 = "$base/$olddir/$id";
  my $success = rename($name1, $name2);
  #if (!$success) {
  #  print "Content-type: text/plain\n\n";
  #  print "Why did I get $! for renaming $name1 to $name2?\n";
  #  exit 0;
  #}
  return $success;
}

sub _get_filenames {
  my ($self, %params) = @_;
  opendir THISDIR, $self->_dirname() or return undef;
  # none of the files we're interested in are hidden;
  my @filelist = grep !/^\./, readdir THISDIR;
  closedir THISDIR;
  if ($self->{grace}) {
    # grace is entered in minutes; need to convert to days
    my $gracedays = $self->{grace} / (24 * 60);
    # skip ones that are newer than the grace period if specified
    my @weeded = ();
    foreach my $name (@filelist) {
      my $path = $self->_dirname() . "/$name";
      if (-M $path > $gracedays) {
        push @weeded, $name;
      }
    }
    @filelist = @weeded;
  }
  $self->{filenames} = \@filelist;
  $self->{count} = scalar(@filelist);
  if ($self->{count}) {
    my @sorted = sort {$a <=> $b} @filelist;
    my $firstname = $sorted[0];
    my $firstpath = $self->_dirname() . "/$firstname";
    $self->{oldestage} = -M $firstpath;
  }
  $self->{namesread} = 1;
}

sub _get_filecontents {
  my ($self, %params) = @_;
  if (!$self->{namesread}) {
    $self->_get_filenames();
  }
  return undef if (!$self->{filenames});
  my @idarray = @{$self->{filenames}};
  foreach my $id (@idarray) {
    my $fname = $self->_dirname() . "/$id";
    next if -d $fname;   # don't read "contents" of subdirectories
    my $str;
    open IN, "< $fname" or next;
    while (<IN>) {
      $str .= $_;
    }
    close IN;
    $self->{file}->{$id} = $str;
  }
  $self->{filesread} = 1;
}

sub get_files {
  my ($self, %params) = @_;
  if (!$self->{filesread}) {
    $self->_get_filecontents();
  }
  return $self->{file};
}

sub get_count {
  my ($self, %params) = @_;
  if (!$self->{namesread}) {
    $self->_get_filenames();
  }
  return $self->{count};
}

sub get_oldest_age {
  my ($self, %params) = @_;
  if (!$self->{namesread}) {
    $self->_get_filenames();
  }
  return $self->{oldestage};
}

sub summarize_oldest_age {
  my ($self, %params) = @_;
  my $age = $self->get_oldest_age(%params);
  my $when;
  if ($age >= 1) {
    $when = int($age) . " day" . (int($age) > 1 ? "s" : "") . " ago";
  } else {
    $age *= 24;
    if ($age >= 1) {
       $when = int($age) . " hour" . (int($age) > 1 ? "s" : "") . " ago";
    } else {
      $age *= 60;
      if ($age >= 1) {
        $when = int($age) . " minute" . (int($age) > 1 ? "s" : "") . " ago";
      } else {
        $when = "just now";
      }
    }
  }
  return $when;
}


sub _initialize {
  my ($self, %params) = @_;
  $self->{name} = $params{name};
  $self->{grace} = $params{grace};
  $self->{dir} = $params{dir} || $DATADIR;
  return $self;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->_initialize(@_);  # uses remaining arguments
}

1;


