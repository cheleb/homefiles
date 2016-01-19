#!/usr/bin/perl
use strict;

use Getopt::Std;
my %options=();
getopts("p:t:", \%options);

die "KAFKA_HOME is not defined\n" unless $ENV{'KAFKA_HOME'};

my @topics = @ARGV;
for my $topic ( @ARGV ){
    print "Delete topic $topic\n";
    
    system "$ENV{'KAFKA_HOME'}/bin/kafka-topics.sh --zookeeper localhost:2181  --delete --topic $topic";
}
