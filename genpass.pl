#!/usr/bin/perl

$num = shift;

$num = 1 if ((!$num) || ($num == 0));

$| = 1;

# First, set up our password generator

#$WORDS = "/usr/dict/words";
$WORDS = "/usr/share/dict/words";
$CHR = "0123456789!@$%^&*./?;:";
$salt = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
@salt = split //, $salt;
@CHR = split //, $CHR;

if (!open(W, "<$WORDS")) {
        print STDERR "Unable to open $WORDS: $!\n";
        exit 1;
}

# Get all lowercase 3 letter words
@WORDS = grep {/^[a-z]{3,7}$/} <W>;
chomp @WORDS;


while ($num) {
        $Password = $WORDS[int(rand($#WORDS + 1))] .
                $CHR[int(rand($#CHR + 1))] .
                $CHR[int(rand($#CHR + 1))] .
                $WORDS[int(rand($#WORDS + 1))] .
                $CHR[int(rand($#CHR + 1))] .
                $CHR[int(rand($#CHR + 1))] .
                $WORDS[int(rand($#WORDS + 1))];

        $numrand = int(rand(4));
        while ($numrand--) {
                substr($Password,int(rand(length($Password)+1)),1) =~ tr/a-z/A-Z/;
        }

        print "$Password\n";
#        print "$Password\t", crypt($Password, $salt[int(rand($#salt + 1))] .
#                $salt[int(rand($#salt + 1))]), "\n";

        $num--;
}
