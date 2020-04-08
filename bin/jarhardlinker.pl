#!/usr/bin/env perl

use strict;

use Getopt::Long;
use File::Next;
use File::Slurp;
use File::stat;
use POSIX;

my $nexus="/opt/nexus/sonatype-work/nexus3/blobs/default/content";
my ($all, $gradle, $maven, $sbt, $debug, $dryRun, $printStats, $relink);

GetOptions ("nexus=s"      => \$nexus,   # String
            "maven"        => \$maven,
            "all"          => \$all,
            "sbt"          => \$sbt, 
            "gradle"       => \$gradle,
            "debug"        => \$debug,
            "print-stats"  => \$printStats,
            "dry-run"      => \$dryRun,
            "relink"       => \$relink
            )   # Numeric
or die("Error in command line arguments\n");
 
my $cachePaths = {
  maven => $ENV{"HOME"} . "/.m2/repository/",
  sbt => $ENV{'HOME'} . '/Library/Caches/Coursier/v1/http/localhost%3A8081/repository/',
  gradle => $ENV{'HOME'} . '/.gradle/caches/modules-2/files-2.1/'
};

my $cacheResolvers = {
  maven => sub {$_[0]},
  sbt => sub {
    my $relative = shift;
    my ($repo, @paths) = split('/', $relative);
    join('/', @paths);
  },
  gradle => sub {
    my $relative = shift;
    my ($groupId, $artifactId, $version, $sha, $filename) = split('/', $relative);
    $groupId =~ s!\.!/!g;
    join('/', $groupId, $artifactId, $version, $filename);
  }
};

my @repositories = ();

if($all){
  @repositories = ("sbt", "maven", "gradle")
}else{
  push @repositories, "sbt" if $sbt;
  push @repositories, "maven" if $maven;
  push @repositories, "gradle" if $gradle;
}
my $nexusFiles = {};
$nexusFiles = buildNexusIndex($nexus) if $relink && @repositories;


foreach my $repository (@repositories) {
  print $repository, "\n";
  die "No repository ($repository)\n" unless -d $cachePaths->{$repository};

  printStats($repository, $cachePaths->{$repository}) if $printStats;
  hardLinkFiles($repository) if $relink;
}

exit(0);

sub hardLinkFiles(){
   my $repository = shift;
   my $cachePath = $cachePaths->{$repository};
   my $resolver = $cacheResolvers->{$repository};

   debug("Hard linking $cachePath");
   my $count=0;
   my $sbtIter = File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $cachePath );
   while ( defined ( my $file = $sbtIter->() ) ) {
       my $relative = substr($file, length($cachePath));
       my $path = $resolver->($relative);
       $count += harlink($path, $file, $repository);
   }

}

sub harlink {
    my $path = shift;
    my $file = shift;
    if($dryRun){
      debug(" 👎 $path") unless $nexusFiles->{$path};
  #    debug(" 👍 $path") if $nexusFiles->{$path};
    }elsif( -e $nexusFiles->{$path}){
      my $st = stat($file);
      return if $st->nlink > 1; 
      unlink $file;
      link  $nexusFiles->{$path}, $file;
    }else{
     debug("[-]  $path"); 
     0
    }
}



sub printStats {
    my $repository = shift;
    my $cachePath = $cachePaths->{$repository};
    my $stats = {};
    my $sbtIter = File::Next::files({ 'file_filter' => sub { /\.(jar)$/ } }, $cachePath );
    while ( defined ( my $file = $sbtIter->() ) ) {
        my $st = stat($file);
        $stats->{'nlink '.$st->nlink}++;
        next if $st->nlink == 1;
        $stats->{"size red"} += $st->size/(1024*1024);
    }

    $stats->{"size red"} = floor($stats->{"size red"})." Mo";

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

sub jarIterator {
  my $cachePath = shift;
  File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $cachePath );
}

sub debug {
    my $msg = shift;
    warn $msg, , "\n" if($debug)
}
