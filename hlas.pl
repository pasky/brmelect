#!/usr/bin/perl

# Copyright TMA 2014
# Brmlab can use this free of charge as long as TMA is member. For other licensing options contact the author.

use strict;
use warnings;
use Data::Dumper;

my $x = 1;
# pocet volenych papalasu
my $funkci;
# prave voleny papalas
my $voleny_papalas = 0;
# kandidati na papalase
my @kand = (undef,);
# listky pro papalase
my @listky;
# stav programu
my $st;
# pocet listku a neplatnych
my ($listky, $neplatne_listky) = (0,0);
# stavova masina
my %sm;
%sm = (
        start => sub {
                $funkci = $_;
                return 'kand';
        },
        kand => sub {
                return 'listky' if /^$/;
                push @kand,$_;
                return 'kand';
        },
        listky => sub {
                return 'volby' if /^$/;
                my $listek = [0,split];
                # doplnit nuly na konci listku
                my @tmp = (0,) x scalar @kand;
                @tmp[0 .. $#$listek] = @$listek;
                $listek = [ @tmp ];
                # je listek platny?
                my $ok = /^[0-9 ]*1[0-9 ]*$/;
                @tmp = sort {$a<=>$b} (grep {$_>0} @$listek) if $ok;
                my $i = 0;
                #{local$"=" ";print "@tmp\n";}
                while ($ok && scalar @tmp) {
                        #print "@tmp $i $ok\n";
                        $ok = (++$i == shift@tmp);
                }
                #{local$"=" ";print "$ok/@tmp\n";}
                #print "$ok listek $_\n";
                ++$neplatne_listky unless $ok;
                ++$listky;
                push @listky, $listek if $ok;

                return 'listky';
        },
        volby => sub {
                die "Nebyl odevzdan ani jeden platny hlasovaci listek." unless $listky - $neplatne_listky;
                #print Dumper(\@listky);
                if (++$voleny_papalas > $funkci) {
                        exit;
                }
                my $kolo = 1;
                my $papalas = undef;
                my $max;
                for my $i (1 .. $#kand) {
                        local$"=" ";
                        my @kandidat = prepocti($i);
                        #print "kolo $i, @kandidat\n";
                }
                while ($kolo <= $#kand) {
                        my @kandidat = prepocti($kolo);
                        #print Dumper(kandidat=>\@kandidat);
                        ($max,$papalas) = (0, undef);
                        for my $i (1 .. $#kandidat) {
                                if ($max < $kandidat[$i]) {
                                        $max = $kandidat[$i];
                                        $papalas = $i;
                                } elsif ($max == $kandidat[$i]) {
                                        undef $papalas;
                                }
                        }
                        #{local$"=" ";print "kolo $kolo, @kandidat\n";}
                        last if defined $papalas;
                        #{local$"=" ";print "$kolo  $papalas $zvolen  @kandidat\n";}
                        $kolo++;
                }
                if (defined $papalas) {
                        print "Byl zvolen $kand[$papalas] v $kolo. kole volby poctem $max hlasu.\n";
                        uprav($papalas);
                        $sm{volby}->();
                } else {
                        $papalas = $_;
                        die "Chybi zaznam o losovani." unless $papalas;
                        print "Byl vylosovan $kand[$papalas].\n";
                        uprav($papalas);
                }
                return 'volby';
        },
);
$st = $sm{start};
sub prepocti($) {
        my ($kolo,) = (@_);
        my @kandidat = (0,) x $#kand;
        for my $listek (@listky) {
                #{no warnings;local$"="| |";print "|@$listek|\n";}
                for my $i (1 .. $#$listek) {
                        ++$kandidat[int$i] if $listek->[$i] > 0 && $listek->[int$i]<=$kolo;
                }
        }
        return @kandidat;
}
sub uprav($) {
        my ($papalas,) = (@_);
        for my $listek (@listky) {
                #{no warnings;local$"="| |";print "|@$listek|\n";}
                #{local$"=" ";print "< @$listek\n";}
                my $poradi = $listek->[$papalas];
		next if $poradi == 0;
		for my $i (1 .. $#$listek) {
			$listek->[$i]-- if $listek->[$i] > $poradi;
		}
                $listek->[$papalas]=0;
                #{local$"=" ";print "> @$listek\n";}
        }
}

while (<>) {
        chomp;
        $st = $sm{$st->()};
}
END {
        print "Odevzdano celkem $listky hlasovacich listku.\n";
        my $platne_listky = $listky - $neplatne_listky;
        print "Z toho $neplatne_listky hlasovacich listku neplatnych a $platne_listky platnych.\n";
}
