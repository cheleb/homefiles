#!/usr/bin/env perl

use strict;

use Getopt::Long;
use File::Next;
use File::Slurp;

my $nexus="/opt/nexus/sonatype-work/nexus3/blobs/default/content";
my ($maven, $sbt, $debug);

GetOptions ("nexus=s"  => \$nexus,   # String
            "maven"    => \$maven,   # string
            "sbt"      => \$sbt,     # string
            "debug"    => \$debug)   # Numeric
or die("Error in command line arguments\n");
 
my $nexusIter = File::Next::files({ 'file_filter' => sub { /\.properties$/ } }, $nexus );

my $count = 0; 
my %files =();
while ( defined ( my $file = $nexusIter->() ) ) {
    #print $file, "\n";
    my %meta = read_file($file) =~ /^([^=]+)=(.*)$/mg;
    #print $meta{'@BlobStore.content-type'}, "\n" unless $meta{'@BlobStore.content-type'} eq "application/java-archive";
    next if $meta{'@BlobStore.content-type'} ne "application/java-archive";
    $file =~ s/\.properties$/.bytes/;
    $files{$meta{'@BlobStore.blob-name'}} = $file;
    #print $meta{'@BlobStore.blob-name'}, "\n";
    $count++;
}


linkSbtFile() if $sbt;


sub linkSbtFile(){
   print "Hard linking sbt\n";
   my $sbtCache = $ENV{'HOME'} . '/Library/Caches/Coursier/v1/http/localhost%3A8081/repository/';
   my $sbtIter = File::Next::files({ 'file_filter' => sub { /\.jar$/ } }, $sbtCache );
   while ( defined ( my $file = $sbtIter->() ) ) {
       my $relative = substr($file, length($sbtCache));
       my ($repo, @paths) = split('/', $relative);
       my $path = join('/', @paths);
       harlink($path, $file) if exists $files{$path};
       print $path, "\n" unless exists $files{$path};
   }
   print "\n";
}

sub harlink {
    my $path = shift;
    my $file = shift;
    die $files{$path} unless -e $files{$path}; 
    unlink $file;
    link  $files{$path}, $file;
}
