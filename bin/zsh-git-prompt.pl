#!/usr/bin/perl

use strict;

use Getopt::Long;
my $warning;
my $cool;
my $reset;
my $debugLevel=0;
GetOptions ("warning=s" => \$warning,     # String
            "cool=s"    => \$cool,        # string
            "reset=s"    => \$reset,        # string
            "debug=i"   => \$debugLevel)  # Numeric
or die("Error in command line arguments\n");

open my $git, "git status --porcelain -b 2> /dev/null |";
exit if $git->eof;

print $warning, '±', $cool, '±', $reset;
my $head = <$git>;

&parseFileStatus($git);
&parseHead($head);
$git->close;
exit;

sub warning {
  ($warning, @_, $reset)
}

sub parseHead {
  if(@_[0] =~ m!^##\s([\w\-]+(?:\.[\w\-]+)*)(?:\.\.\.([\w\-\.]+)/([\w\-\.]+)(?:\s(?:\[(?:(?:(ahead)\s(\d+))?(?:,\s)?(?:(behind)\s(\d+))?|(gone))?\])?)?)?!){
    if($debugLevel){
      my @oo = ($1, $2, $3, $4, $5, $6, $7, $8);
      &dump(@oo);
    }
    #     $1        $2         $3            $4        $5       $6         $7       $8 
    my ($branch, $remote, $remoteBranch,$is_ahead,$n_ahead,$is_behind, $n_behind, $gone) = ($1, $2, $3, $4, $5, $6, $7, $8);
    my @remote=();
    
    push @remote, "⬆️  $n_ahead" if $is_ahead;
    push @remote, "⬇️  $n_behind" if $is_behind;
    print '(', join(', ', @remote), ") " if @remote;
    
    my @branch=();
    if($gone){
      push @branch, "🔥 ", &warning($branch), "🔥"
    }elsif($remote){
      push @branch, $branch unless $branch eq "master";
      push @branch, &warning($remote),'/', unless $remote eq "origin";
      push @branch, &warning($remoteBranch) unless $branch eq $remoteBranch;
    } else {
      push @branch, "🎉 ", &warning($branch)
    }
    print '[', @branch, ']' if @branch;
    
    if($is_ahead && $is_behind){
    print "⚠️"
    }else{
      print "🕥" if $is_behind;
      print "✨" if $is_ahead;
    }
  }
  elsif($debugLevel){
    if($_[0] =~ m!^##\s([\w\-\.]+)!){
      warn "OOO-->$1<--\n";
    }
    warn "-->", @_[0], "<--\n"
  }
}

sub parseFileStatus {
  my @checks = (
    sub {@_[0] =~ /^[AMRD]/ && "🚀"},      #STAGED 
    sub {@_[0] =~/^.[MTD]/ && "🚧"},       #UNSTAGED
    sub {@_[0] =~/^\?\?/ && "👀"},         #UNTRACKED
    sub {@_[0] =~/^UU\s/ && "💥"},         # UNMERGED
    sub {@_[0] =~ /^## .*diverged/ && "😨"} # DIVERGED
  );
  while(<$git>){
    for (my $i=@checks-1; $i >= 0; $i--){
      if(my $state = $checks[$i]->($_)){
            splice @checks, $i, 1;
            print ' ', $state;
            last;
        }
    }
  }
}

sub dump {
    print "\n";
    while (my ($i, $e) = each @_) {
     warn $i+1, " -> $e\n";
   }
}
