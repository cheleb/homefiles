#!/usr/bin/env perl

use strict;

use Getopt::Long;
use File::Next;
use File::Slurp;
use File::stat;

my $nexus="/opt/nexus/sonatype-work/nexus3/blobs/default/content";
my ($gradle, $maven, $sbt, $debug, $dryRun, $unmanaged);

GetOptions ("nexus=s"  => \$nexus,   # String
            "maven"    => \$maven,   # string
            "sbt"      => \$sbt,     # string
            "gradle"   => \$gradle,
            "debug"    => \$debug,
            "dry-run"  => \$dryRun,
            "unmanaged" => \$unmanaged
            )   # Numeric
or die("Error in command line arguments\n");
 
my $mavenCache = $ENV{"HOME"} . "/.m2/repository/";
my $sbtCache = $ENV{'HOME'} . '/Library/Caches/Coursier/v1/http/localhost%3A8081/repository/';
my $gradleCache = $ENV{'HOME'} . '/.gradle/caches/modules-2/files-2.1/';


unmanaged() if $unmanaged;

my $nexusFiles = buildNexusIndex($nexus);


hardLinkFiles("sbt", $sbtCache, sub {
    my $relative = shift;
    my ($repo, @paths) = split('/', $relative);
    join('/', @paths);
}) if $sbt;

hardLinkFiles("mvn", $mavenCache) if $maven;
hardLinkFiles("gradle", $gradleCache, sub {
    my $relative = shift;
    my ($groupId, $artifactId, $version, $sha, $filename) = split('/', $relative);
    $groupId =~ s!\.!/!g;
    join('/', $groupId, $artifactId, $version, $filename);
} ) if $gradle;


sub hardLinkFiles(){
   my $type = shift;
   my $cachePath = shift;
   my $resolver = shift
    || sub {$_[0]};


   my $stats = {};
   debug("Hard linking $cachePath");
   my $count=0;
   my $sbtIter = File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $cachePath );
   while ( defined ( my $file = $sbtIter->() ) ) {
       my $relative = substr($file, length($cachePath));
       my $path = $resolver->($relative);
       $count += harlink($path, $file, $type), $stats;
   }
   printStats($type, $count, $cachePath, $stats);

}

sub harlink {
    my $path = shift;
    my $file = shift;
    my $type = shift;
    my $stats = shift;
    if($dryRun){
      debug(" 👎 $path") unless $nexusFiles->{$path};
  #    debug(" 👍 $path") if $nexusFiles->{$path};
    }elsif( -e $nexusFiles->{$path}){
      my $st = stat($file);
#      return 0 if $st->nlink > 1; 
      $stats->{"newly size red"} += $st->size;
      $stats->{'newly hardlinked'}++;
      unlink $file;
      link  $nexusFiles->{$path}, $file;
      1
    }else{
     $stats->{'unmanaged'}++;
     debug("[-]  $path"); 
     0
    }
}



sub printStats {
    my $type = shift;
    my $count = shift;
    my $cachePath = shift;
    my $stats=shift;
    print $type, ': ', $count, "\n";
    my $sbtIter = File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $cachePath );
    while ( defined ( my $file = $sbtIter->() ) ) {
        my $st = stat($file);
        next if $st->nlink == 1;
        $stats->{"size red"} += $st->size;
        $stats->{'nlink '.$st->nlink}++;
        print $file, "\n" if $st->nlink == 4;
    }
    foreach my $key  (sort keys %{$stats}) {
        print "\t", $key, ': ', $stats->{$key}, "\n"
    }

}

sub buildNexusIndex {
  my $nexus = shift;
  my $index = {};
#  return $index if $dryRun;
  debug("Build nexus install from:\n\t$nexus" );
  my $nexusIter = File::Next::files({ 'file_filter' => sub { /\.properties$/ } }, $nexus );
  while ( defined ( my $file = $nexusIter->() ) ) {
    my %meta = read_file($file) =~ /^([^=]+)=(.*)$/mg;
    next if $meta{'@BlobStore.content-type'} ne "application/java-archive";
    $file =~ s/\.properties$/.bytes/;
    my $path = $meta{'@BlobStore.blob-name'};
    my $uriEncodedPath = $path;
    $uriEncodedPath =~ s/\+/%2B/g;
    if($path ne $uriEncodedPath){
      debug("encoded($path) |--> $uriEncodedPath");
      $index->{$uriEncodedPath} = $file;
    } else {
      $index->{$path} = $file;
    }
  }
  $index
}

sub unmanaged {
  my $stats = {};
  unmanagedInCache("sbt", $sbtCache, $stats) if $sbt;  
  foreach my $key  (sort keys %{$stats}) {
        print "\t", $key, ': ', $stats->{$key}, "\n"
    }
  exit
}

sub unmanagedInCache {
  my $type = shift;
  my $cache = shift;
  my $stats = shift;

  my $iter = jarIterator($cache);
  while ( defined ( my $file = $iter->() ) ) {
    my $st = stat($file);
    next unless $st->nlink == 1;
    print $file, "\n";
    $stats->{"unmanaged in $type"}++
  }
}


sub jarIterator {
  my $cachePath = shift;
  File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $cachePath );
}

sub debug {
    my $msg = shift;
    warn $msg, , "\n" if($debug)
}