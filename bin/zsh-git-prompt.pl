#!/usr/bin/perl

use strict;

use Term::ANSIColor;

open my $git, "git status --porcelain -b|";
my $head = <$git>;
#print "-->",$head, "<--\n";
print &parseFileStatus($git), " - ", &parseHead($head), "]\n";
exit;

sub parseHead {
  if(@_[0] =~ m!(\w+)\.\.\.(\w+)/(\w+)\s(\[(?:(ahead) (\d+))?(?:, )?(?:(behind) (\d+))?\])?!){
    #     $1        $2          $3                 $4            $5       $6        $7          $8 
    my ($branch, $remote, $remoteBranch, $is_ahead_or_behing,$is_ahead,$n_ahead,$is_behind, $n_behind) = ($1, $2, $3, $4, $5, $6, $7, $8);
    my @status = ();
    if($is_ahead_or_behing){
        push @status, "(";
        push @status, "⬆️  $n_ahead" if $is_ahead;
        push @status, "," if $n_ahead && $is_behind;
        push @status, "⬇️  $n_behind" if $is_behind;
        push @status, ") ";
    }
    push @status, $branch;
#    push @status, '...', color('red') , $remote, color('reset') unless $remote eq "origin";
    push @status, '...', $remote unless $remote eq "origin";
    push @status,  "$remoteBranch" unless $branch eq $remoteBranch;
    #my @oo = ($1, $2, $3, $4, $5, $6, $7, $8);
    #&dump(@oo);
    @status
  }
}

sub parseFileStatus {
  my @checks = (
    sub {@_[0] =~ /^[AMRD]/ && "🚀"},      #STAGED
    sub {@_[0] =~/^.[MTD]/ && "🔢"},       #UNSTAGED 
    sub {@_[0] =~/^\?\?/ && "👀"},         #UNTRACKED
    sub {@_[0] =~/^UU\s/ && "🔴"},         # UNMERGED
    sub {@_[0] =~ /^## .*diverged/ && "‼️"} # DIVERGED
  );
  my @states;
  while(<$git>){
    for (my $i=@checks-1; $i >= 0; $i--){
      if(my $state = $checks[$i]->($_)){
            splice @checks, $i, 1;
            push @states, $state;
            last;
        }
    }
  }
  @states
}

sub dump {
    print "\n";
    while (my ($i, $e) = each @_) {
      print $i+1, " -> $e\n";
    }
}
