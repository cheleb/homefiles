#!/usr/bin/perl
use strict;

use Getopt::Std;
my %options=();
getopts("p:r:", \%options);

die "KAFKA_HOME is not defined\n" unless $ENV{'KAFKA_HOME'};

my $topic = $options{'t'} 
|| "zozo";

my $par = $options{'p'}
|| 3;
my $rep = $options{'r'}
|| 1;
my @topics = @ARGV;
for my $topic ( @ARGV ){
    print "Create topic $topic\n";
    system "$ENV{'KAFKA_HOME'}/bin/kafka-topics.sh --zookeeper localhost:2181  --create --topic $topic --replication-factor $rep --partitions $par";
}




