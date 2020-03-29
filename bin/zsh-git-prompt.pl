#!/usr/bin/perl

use strict;

my $red = shift;
my $green = shift;
my $reset = shift;
open my $git, "git status --porcelain -b 2> /dev/null |";
exit if $git->eof;

print $red, '±', $green, '±', $reset;
my $head = <$git>;
#print "-->",$head, "<--\n";
&parseFileStatus($git);
&parseHead($head);
$git->close;
exit;

sub parseHead {
  if(@_[0] =~ m!([\w-]+)\.\.\.([\w-]+)/([\w-]+)\s(\[(?:(ahead) (\d+))?(?:, )?(?:(behind) (\d+))?\])?!){
    #     $1        $2          $3                 $4            $5       $6        $7          $8 
    my ($branch, $remote, $remoteBranch, $is_ahead_or_behing,$is_ahead,$n_ahead,$is_behind, $n_behind) = ($1, $2, $3, $4, $5, $6, $7, $8);
    if($is_ahead_or_behing){
        print "(";
        print "⬆️  $n_ahead" if $is_ahead;
        print "," if $n_ahead && $is_behind;
        print "⬇️  $n_behind" if $is_behind;
        print ") ";
    }
    print '[';
    print $branch;
    print $red, '...', $remote, $reset unless $remote eq "origin";
    print $red, $remoteBranch, $reset unless $branch eq $remoteBranch;
    print ']',"\n";
    #my @oo = ($1, $2, $3, $4, $5, $6, $7, $8);
    #&dump(@oo);
    if($is_ahead && $is_behind){
    print "⚠️"
    }else{
      print "🕥" if $is_behind;
      print "✨" if $is_ahead;
    }
    print "\n";
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
            print ' ', $state, "\n";
            last;
        }
    }
  }
}

#sub dump {
#    print "\n";
#    while (my ($i, $e) = each @_) {
#      print $i+1, " -> $e\n";
#    }
#}
