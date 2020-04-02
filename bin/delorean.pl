#!/usr/bin/env perl

use strict;

use Getopt::Long;
my $from;
my $to;
my $debugLevel=0;
my $sessionFile = "/tmp/delorean-" . getpwuid( $< );
GetOptions ("from=s" => \$from,     # String
            "to=s"    => \$to,        # string
            "debug=i"   => \$debugLevel)  # Numeric
or die("Error in command line arguments\n");

my $branch = branch(); 

$to = headCommit();

my $continueSession = -e $sessionFile;

newSession() unless $continueSession;

if(branch() eq "HEAD"){
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
  my $branch = branch();
  print " 🚀 ", $branch, "\n";
  debug("from: $from");
  debug("to: $to");
  debug("Session file $sessionFile");
  system "git log --reverse --oneline --no-abbrev-commit $branch > $sessionFile";  
  debug("Init history.");
  system "git checkout $from" unless $continueSession;
  debug("Starting...");
  debug(headCommit())
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

sub headCommit {
    open my $currentGitFH, "git rev-parse HEAD 2> /dev/null |";
    die " ☠️  Twiligh zone \n" if $currentGitFH->eof;
    my $headCommit = <$currentGitFH>;
    $currentGitFH->close();
    chomp($headCommit);
    return $headCommit
}

sub branch {
    open my $git, "git status --porcelain -b 2> /dev/null |";
    die "\n\t ☠️  Not a git repository...\n" if $git->eof;
    my $line = <$git>;
    return $1 if($line =~ m!^##\s([\w\-]+(?:\.[\w\-]+)*).*!);
    die "No branche: $line ?"
}

sub debug {
    print @_, "\n" if $debugLevel;
}
