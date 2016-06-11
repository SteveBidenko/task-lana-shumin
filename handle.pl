#!/usr/bin/env perl

my %enclosure = (
    isOpened => 0,
    headline => '',
    linkToParent => undef,
    length => 0,
    enclosure => []
);
my $reference = \%enclosure;

sub printEnclosureHash {
    my $rf = shift(@_);
    # Output headline
    print $rf->{headline};
    # recursively print the enclosure
    for my $line (@{$rf->{enclosure}}) {
        if (ref($line) eq "HASH") {
            printEnclosureHash ($line);
        } else {
            print $line;
        }
    }
}

while (<>) {
    chomp $_;
    if ($_ =~ /^\+/) {
        s/^\+\s//;
        s/=00/=/;
        my @line = split('=', $_);
        $output = " $line[$0]";
        shift @line;
        $output .= "^VAR ($line[$0])^\n";
        if ($reference->{isOpened}) {
            # Here we will print $output into an array which is presented by link
            push @{$reference->{enclosure}}, $output;
            $reference->{length}++;
        } else {
            print $output;
        }
    } else {
        if ($_ =~ /^net[0-9]/) {
            # at this point I want to count the number of lines from the ^net#
            # until the line before "netend#" and put that number in place of the @ below
            # This can go up to 6 different net levels.
            # You have to count the # of lines after the net1 until the line that contains the 1st occurence
            # of netend# (so net1 until the 1st netend1, net2 until the 1st netend2, etc. remember you are only counting lines that
            # have either a net[1-9] or a "+" in the 1st position.
            s/net[0-9]/ /;
            # Check if the enclosure is already opened
            if ($reference->{isOpened}) {
                # Create a new enclosure
                $newReference = {
                    isOpened => 1,
                    linkToParent => $reference,
                    length => 0,
                    headline => "$_",
                    enclosure => []
                };
                push @{$reference->{enclosure}}, $newReference;
                $reference = $newReference;
            } else {
                # Open this enclosure
                $reference->{isOpened} = 1;
                $reference->{headline} = "$_";
            }
         } elsif ($_ =~ /^netend[0-9]/) {
            # Here we added summary information to headline
            $reference->{headline} .= "^NET$reference->{length}^L-\n";
            # Close reference
            $reference->{isOpened} = 0;
            # Set reference to the parent if it's set or output whole the enclosure
            if ($reference->{linkToParent}) {
                $reference->{linkToParent}->{length} += $reference->{length};
                $reference = $reference->{linkToParent};
            } else {
                # Here $reference is a head of all the enclosures so we output it
                # Output enclosure. It may be recursive output.
                printEnclosureHash $reference;
                # Clean enclosure after output
                $reference->{enclosure} = [];
                $reference->{length} = 0;
            }
         }
    }
}
