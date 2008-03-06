use strict;
use warnings qw(FATAL all);
use Error::Die; # DEPEND
use Mfm; # DEPEND
use SimpleIO::Cat; # DEPEND
use SimpleIO::Write; # DEPEND
use File::Path;

my $cmd = @ARGV ? shift : 'build';

if($cmd eq 'build') {
  do_clean();

  get('BUILD')->run_rules;
  get($_)->run_rules foreach cat('BUILD');
  $_->run_finalize foreach targets;

  write_makefile('Makefile',
    sort { $a->{priority} <=> $b->{priority} || $a cmp $b } targets
  );
  write_file('FILES', sort(@FILES)) if @FILES;
  write_file('CLEAN', sort(@CLEAN)) if @CLEAN;
  write_file('REALLYCLEAN', sort(@REALLYCLEAN)) if @REALLYCLEAN;
}

elsif($cmd eq 'clean') {
  do_clean();
}

elsif($cmd eq 'reallyclean') {
  do_clean();
  foreach my $f (eval { cat('REALLYCLEAN') }, qw(REALLYCLEAN)) {
    eval { rmtree($f) }
  };
}

elsif($cmd eq 'borrow') {
  borrow($_) foreach @_;
}

else {
  die "unknown command: $cmd";
}

exit 0;

sub do_clean {
  foreach my $f (
      eval { cat('CLEAN') },
      qw(Makefile FILES CLEAN)) {
    eval { rmtree($f) };
  }
}

sub write_makefile {
  my $fn = shift;

  my $fh = IO::File->new("$fn.tmp", 'w')
    or die "unable to open $fn for writing: $!";

  print $fh "# Automatically generated by mfm; do not edit!\n";
  $_->write_makefile($fh) foreach @_;

  $fh->close
    or die "unable to write to $fn: $!";
  rename("$fn.tmp", $fn)
    or die "unable to rename $fn.tmp to $fn: $!";
}
