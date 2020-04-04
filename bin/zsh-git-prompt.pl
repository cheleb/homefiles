#!/usr/bin/env perl

use strict;

use Getopt::Long;

use MetaBookMarks::GitPrompt;

my $warning;
my $cool;
my $reset;
my $debug=0;
GetOptions ("warning=s" => \$warning,     # String
            "cool=s"    => \$cool,        # string
            "reset=s"    => \$reset,        # string
            "debug=i"   => \$debug)  # Numeric
or die("Error in command line arguments\n");


my $prompt = gitPrompt($warning, $cool, $reset, $debug);

