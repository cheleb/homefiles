#!/usr/bin/env perl

use strict;

use Getopt::Long;
use MetaBookMarks::Git;

my $from;
my $to;
my $debugLevel=0;
my $sessionFile = "/tmp/delorean-" . getpwuid( $< );
my $dryRun;
GetOptions ("from=s"   => \$from,         # String
            "to=s"     => \$to,           # string
            "debug=i"  => \$debugLevel,   # Numeric
            'dry-run'   => \$dryRun)      # String
or die("Error in command line arguments\n");

my $repo = MetaBookMarks::Git->repository();

my $continueSession = -e $sessionFile;

my $branch = $repo->branch(); 

$to = $repo->headCommit();

dryRun() if $dryRun;

die "\n\t 💀 Repository has changes!\n" if $repo->isDirty();

newSession() unless $continueSession;

if($repo->isDetachedHead()){
  my $notDone;
  do{
    startOrContinueSession();
    $notDone = <STDIN>;
    chomp($notDone)
  }while($notDone eq "")
} else {
  unlink $sessionFile;
  die "\n\t 💥 Not HEAD\n\t($sessionFile deleted)\n";
}

sub newSession {
  die "\n\t 💥 Start commit must be provided with:\n\t\t --from COMMIT-HASH\n" unless $from;
  my $branch = $repo->branch();
  print " 🚀 ", $branch, "\n";
  debug("from: $from");
  debug("to: $to");
  debug("Session file $sessionFile");
  system "git log --reverse --oneline --no-abbrev-commit $branch > $sessionFile";  
  debug("Init history.");
  system "git checkout $from" unless $continueSession;
  debug("Starting...");
  debug($repo->headCommit())
}

sub startOrContinueSession {
    &debug("Continuing...") if $continueSession;
    open my $history, "< $sessionFile" 
      || die "Road is broken\n";
    my $prev=<$history>;
    my $current;
    my $nextSha;
    my $nextComment;

    my $headCommit = headCommit();

    while(my $commitLine=<$history>){
      chomp($commitLine);
      if($commitLine =~ m/^(\w+)\s(.*)/){
       my ($sha, $comment) = ($1,$2);
       if($sha eq $headCommit){
          my $nextCommitLine = <$history>;
          chomp($nextCommitLine);
          if($nextCommitLine =~ m/^(\w+)\s(.*)/){
            ($nextSha, $nextComment) = ($1,$2);
            print "\n\t ⏩ ", $nextComment, "\n\n";
          }else{
              die $nextCommitLine
          }
          last
       }
     }
    }
     if($nextSha eq $to) {
       system "git checkout $branch";
       exit(0)
     }elsif($nextSha){
       debug($nextComment, "==>", $nextSha);
       system "git checkout $nextSha 2> /dev/null"; 
     }
    
    $history->close();   
}

sub nextCommit {
   
}

sub prevCommit {
    
}

sub dryRun {
  my $branch = $repo->branch();
  unless($continueSession){
    die "\n\t 💥 Start commit must be provided with:\n\t\t --from COMMIT-HASH\n" unless  $from;
  }

  print " 🚀 ", $branch, "\n";
  print "from: $from", "\n";
  print "to: $to", "\n";
  print "Session file $sessionFile", "\n";
  print "CMD: git log --reverse --oneline --no-abbrev-commit $branch > $sessionFile", "\n";
  print "Init history.", "\n";
  print "CMD: git checkout $from", "\n" unless $continueSession;
  print "Starting...", "\n";
  exit(0)
}

sub debug {
    print @_, "\n" if $debugLevel;
}
