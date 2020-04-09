#!/usr/bin/env perl

#
# Time travel.
#
use strict;

use Getopt::Long;
use MetaBookMarks::Git;

use Term::UI;

my $from;
my $to;
my $debugLevel=0;
my $dryRun;
GetOptions ("from=s"   => \$from,         # String
            "to=s"     => \$to,           # string
            "debug=i"  => \$debugLevel,   # Numeric
            'dry-run'   => \$dryRun)      # String
or die("Error in command line arguments\n");

my $git = MetaBookMarks::Git->repository();

my $branch = $git->branch(); 

$to = $git->headCommit();

dryRun() if $dryRun;

die "\n\t 💀 Repository has changes!\n" if $git->isDirty();

my @commits = newSession();

my $index=0;
do{
  $index = nextCommit($index);
  my $term = Term::ReadLine->new('brand');
  print "\t";
  my $next = $term->ask_yn(
                            prompt => "Next",
                            default => 'y',
                    );
  end() unless $next;
  #$index = $i if( 0 <= $i && $i < $#commits);
}while($index);


sub newSession {
  die "\n\t 💥 Start commit must be provided with:\n\t\t --from COMMIT-HASH\n" unless $from;
  my $branch = $git->branch();
  print " 🚀 ", $branch, "\n";
  debug("from: $from");
  debug("to: $to");
  initCommits()
}

sub initCommits {
  ("$from 🚀\n", $git->log('--reverse', '--oneline', '--no-abbrev-commit', $branch, "$from...$to"))
}

sub nextCommit {
  my $index = shift;
  if($index == $#commits){
    end()
  }else{ 
    my $commitLine = $commits[$index];
    if($commitLine =~ /^(\w+)\s(.*)/){
      my ($sha1, $comment) = ($1, $2);
      print " ⏩ $comment\n";
      $git->checkout($sha1);
      ++$index
    }
  }
}

sub prevCommit {
    
}

sub end {
  $git->checkout($branch);
  exit(0)
}

sub dryRun {
  my $branch = $git->branch();

  die "\n\t 💥 Start commit must be provided with:\n\t\t --from COMMIT-HASH\n" unless  $from;


  print " 🚀 ", $branch, "\n";
  print "from: $from", "\n";
  print "to: $to", "\n";

  print "\n";

  for my $commitLine ( initCommits() ){
    print "\t", $commitLine, "\n"
  }
  exit(0)
}

sub debug {
    print @_, "\n" if $debugLevel;
}
