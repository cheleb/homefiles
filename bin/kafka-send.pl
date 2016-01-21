#!/usr/bin/perl
use strict;

use Getopt::Std;
my %options=();
getopts("e:t:r:s:m:f:bcdwp", \%options);

die "KAFKA_HOME is not defined\n" unless $ENV{'KAFKA_HOME'};

my $boom = $options{'e'};
my $topic = $options{'t'} ||
    "test";

my $n = shift ||
    1;

my $s = $options{'s'} ||
    1;

my $range = $options{'r'} ||
    1 ;

my $msexp = 500;


my $messageTmpl = $options{'m'};

my $messageCB;

my $idTmpl = "5f2d9909-17ac-4c0b-bd67-71e1c7bf492d-%d";

sub buildMessage {
    my $i = shift;
    return sprintf($messageTmpl, $i);
}


if($options{'f'}){
  local $/ = undef;
  open FILE, $options{'f'} or die "Couldn't open file: $!";
  binmode FILE;
  $messageTmpl = <FILE>;
  chomp($messageTmpl);
  close FILE;
  $messageCB = \&buildMessage;
} elsif($options{'c'}){
    $messageCB = sub {
        $_[0]
    }
}







die "Choose a message to send -m | -f | -p\n" unless $messageCB;

if($options{'d'}){
    print $messageCB->(666) . "\n";
    exit
}

my @topics;
if($range > 1){
    @topics = map {$topic.$_} (1..$range);
}else{
    @topics = ($topic);
}

foreach my $top ( @topics ){
    print "Sending $n events to $top\n";
    &send($top, $n);
}

sub send {
    my $topic = shift;
    my $n = shift;
    open KAF, "|$ENV{'KAFKA_HOME'}/bin/kafka-console-producer.sh --metadata-expiry-ms $msexp --broker-list localhost:9092,localhost:9192 --topic $topic";
    
    for(my $i=0; $i< $n; $i++){
        print KAF $messageCB->($i) . "\n" if $i % $s == 0; 
    }
    
    close KAF
}


