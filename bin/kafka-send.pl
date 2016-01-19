#!/usr/bin/perl
use strict;

use Getopt::Std;
my %options=();
getopts("e:t:r:s:abcdwp", \%options);

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

my $message;

sub buildAuction {
    my $i = shift;
    my $tmpl = <<EOT;
{"app":{"bundle":"784865098","cat":["IAB9","IAB9-30","games"],"id":"1fea0aa1a2ba4c54b8ed8d8623cfb68a","name":"FR_Duelquiz_iOS","publisher":{"id":    "3d608beaae34442aa3ca8eb54be6bf05","name":"FEO Media AB"},"storeurl":"https://itunes.apple.com/app/duel-quiz/id784865098","ver":"6.0.11"},"at":2,    "badv":["bestgameklub.com","bigfishgames.com","bipmod.com","bipmod.fr","borntoberichandroid.smashatomsoftwarellc.com","cellfish.com","cervomedia.    com","doubledowncasino.com","dragoncity.socialpoint.com","dragonlandsios.socialquantum.com","enel.it","etermax.com","gagnerdescadeaux.com",          "galaxyempire.tap4fun.com","gameofwar-fireage.addmired","inc.com","gametwist.com","grepolisappios.innogames.com","http://enjoythegames.mobi/",       "http://flexidea.ro","http://onlinegamez.mobi/","http://sdc.tre.it/","http://www.playweez.com/?                                                      t2c=a0a0646d35ab18bea98234185fde5d2d4ada&ptn=sfr_liquidm","http://yourgames.mobi/","lovoo.com","lovooios.lovoogmbh.com","mbttd.com","msplash-it.     bestgameklub.com","netintheworld.com","nitw","powerfulmedia.fr","quiz-fever.de","quizpeoplectc.reactivpub.com","sonymobile.com","squeezmeios.        studiocadet.com","ss_centro_flurrycom_flurry_appcircle_cpc_ct_320x50_mar2014.cthealthexchange001.com","tel:","tel:0899025093","tel:0899025232","tel: 0899025722","tel:0899025723","tel:0899025728","tel:0899028539","wap.spielplatzplus.de","www.kia.com","www.lovoo.com","yodarling.gorillagaminggmbh.   com"],"bcat":["IAB25","IAB26","IAB7-39","IAB8-18","IAB8-5","IAB9-7","IAB9-9"],"device":{"carrier":"208-01","connectiontype":3,"devicetype":1,"dnt":0,"dpidmd5":"33b190e1d7aa43942fe3ab0a085d4722","dpidsha1":"ba1d467039840adf5062edb650dc3d70c98764e2","ext":{"idfa":"78439D50-BB8B-476C-9666-           5CAF38D9A77F"},"geo":{"city":"Paris","country":"FRA","region":"A8"},"ip":"80.12.35.215","js":1,"language":"fr","make":"Apple","model":"iPhone 6",    "os":"iOS","osv":"9.0","ua":"Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13A344"},"id": "5f2d9909-17ac-4c0b-bd67-71e1c7bf492d-%d","imp":[{"banner":{"api":[3,5],"battr":[1,2,3,5,6,7,8,9,10,13,14],"btype":[4],"ext":{"nativebrowserclick":1},  "h":50,"pos":1,"w":320},"bidfloor":1.390,"displaymanager":"mopub","displaymanagerver":"3.10.0","ext":{"secure":1},"id":"1","instl":0,"tagid":        "11af122b73d845bcb45248c9f61a1416"}]}
EOT

     chomp($tmpl);

return sprintf($tmpl, $i);


}


if($options{'a'}){
    $message = \&buildAuction;
} elsif($options{'c'}){
    $message = sub {
        $_[0]
    }
}

die "Choose a message to send -a | -b | -p\n" unless $message;

if($options{'d'}){
    print $message->(666) . "\n";
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
	    print KAF $message->($i) . "\n" if $i % $s == 0; 
    }

    close KAF
}


