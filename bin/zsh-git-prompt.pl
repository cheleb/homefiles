#!/usr/bin/perl

use strict;
use Git;

my $repo = Git->repository;
my ($head, @output) = $repo->command("status",  "--porcelain", "-b");


sub parseHead {
  if(@_[0] =~ m!(\w+)\.\.\.(\w+)/(\w+)(?:\s)(\[((ahead) (\d+))?(, )?((behind) (\d+))?\])?!){
    my ($branch, $remote, $remoteBranch, $is_ahead_or_behing,,$is_ahead, $n_ahead,,,$is_behind, $n_behind) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
    my @status = ();~
    push @status, $branch;
    push @status, "...$remote/" unless $remote eq "origin";
    push @status,  "$remoteBranch" unless $branch eq $remoteBranch;
    my ($branch, $remote, $remoteBranch, @oo) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
    &dump(@oo);
    @status
  }
}

sub parseFileStatus {
  my %check = (
    'STAGED' => sub {@_[0] =~ /^[AMRD]/ && "🚀"},
    'UNSTAGED' => sub {@_[0] =~/^.[MTD]/ && "🔢"},
    'UNTRACKED' => sub {@_[0] =~/^\?\?/ && "👀"},
    'UNMERGED' => sub {@_[0] =~/^UU\s/ && "🔴"},
    'DIVERGED' => sub {@_[0] =~ /^## .*diverged/ && "‼️"}
  );
  my @states;
  foreach my $line (@_){
    while (my($name, $check) = each (%check)) {
        if(my $state = $check->($line)){
            delete $check{$name};
            push @states, $state;
        }
    }
  }
  @state
}

print parseHead($head), parseFileStatus(@output), "\n";



sub dump {
    print "\n";
    while (my ($i, $e) = each @_) {
      print $i+1, " -> $e\n";
    }
}
