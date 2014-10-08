#!/usr/bin/perl
# (c) Petr Baudis  2011, 2014  MIT licence
# 
# Generate PDF with ballots.
# Expects number of ballots as argument and names on stdin.

use strict;
use warnings;


# -- User configuration --

our @paper = (598, 842); # A4, 72dpi
our @margin = (72, 72);
our @ballot = (147, 36);
our $filename = 'ballots.pdf';

our $fontface = 'Arial';
our $ffontface = 'Courier New';
# large, normal, small
our @fontsize = (26, 11, 8);
our @linespacing = (18, 13, 10);
our $topmargin = 2;

our $contact = 'brmelect: your votes are safe with us';

# -- User configuration end --


use lib 'perl';
use List::Util qw(min);
use List::MoreUtils qw(pairwise);
use Cairo;

my $n_ballots = pop @ARGV;
my @names;
while (<>) {
	chomp;
	push @names, $_;
}

$ballot[1] += @names * ($linespacing[1] + $fontsize[1] + 5);

our $surface = Cairo::PdfSurface->create ($filename, @paper);

# Effective surface area
our @surfsize = pairwise { $a - $b * 2 } @paper, @margin;
# Grid layout on effective surface
our @grid = pairwise { int($a / $b) } @surfsize, @ballot;
# Grid surface area

our @gridsurfsize = pairwise { $a * $b } @grid, @ballot;
# Start of grid surface so that it is centered on the paper
our @gridsurfstart = pairwise { ($a - $b) / 2 } @paper, @gridsurfsize;

sub gen_token {
	my $token = '';
	my @chars = ('a'..'z', '0'..'9');
	for (1..5) {
		$token .= $chars[rand @chars];
	}
	return($token);
}

# Produce a context for single ballot, starting at coordinates [0,0]
sub ballot_cr {
	my ($surface, $cell) = @_;
	my @startM = pairwise { $a * $b } @ballot, @$cell;
	my @start = pairwise { $a + $b } @gridsurfstart, @startM;

	my $cr = Cairo::Context->create($surface);
	$cr->translate(@start);

	$cr->set_source_rgb(0, 0, 0);
	$cr->set_line_width(1);
	$cr;
}

# Centered text with top border at $$y. $size is index in font config above.
sub ballot_text_centered {
	my ($cr, $y, $face, $slant, $weight, $size, $text) = @_;
	$$y += $linespacing[$size] / 2;

	$cr->select_font_face($face, $slant, $weight);
	$cr->set_font_size($fontsize[$size]);
	my $textents = $cr->text_extents($text);
	my $fextents = $cr->font_extents();
	$$y += $fextents->{height};
	$cr->move_to(($ballot[0] - $textents->{width}) / 2, $$y);
	$cr->show_text($text);

	$$y += $linespacing[$size] / 2;
}

sub ballot_text_plus_box {
	my ($cr, $y, $face, $slant, $weight, $size, $text) = @_;
	$$y += $linespacing[$size] / 2;

	$cr->select_font_face($face, $slant, $weight);
	$cr->set_font_size($fontsize[$size]);
	my $textents = $cr->text_extents($text);
	my $fextents = $cr->font_extents();
	$$y += $fextents->{height};
	$cr->move_to(45, $$y);
	$cr->show_text($text);

	$cr->rectangle(15, $$y - $fontsize[$size], 20, $fontsize[$size] * 3 / 2);
	$cr->stroke;

	$$y += $linespacing[$size] / 2;
}

sub ballot {
	my ($cr, $names) = @_;

	$cr->rectangle(0, 0, @ballot);
	$cr->stroke;


	my $ypos = $topmargin + $linespacing[0] / 2;
	# ballot_text($cr, \$ypos, $fontface, 'normal', 'bold', 0, $host);
	# ballot_text($cr, \$ypos, $ffontface, 'normal', 'normal', 1, $mac);
	for my $name (@$names) {
		ballot_text_plus_box($cr, \$ypos, $fontface, 'normal', 'normal', 1, $name);
	}
	my $tok = gen_token();
	print($tok."\n");
	ballot_text_centered($cr, \$ypos, $fontface, 'italic', 'normal', 2, $tok);
	ballot_text_centered($cr, \$ypos, $fontface, 'italic', 'normal', 2, $contact);
}


my ($x, $y) = (0, 0);

for my $n (1..$n_ballots) {
	ballot(ballot_cr($surface, [$x, $y]), \@names);

	$y++;
	if ($y >= $grid[1]) {
		$y = 0; $x++;
		if ($x >= $grid[0]) {
			my $cr = Cairo::Context->create($surface);
			$cr->show_page;
			($x, $y) = (0, 0);
		}
	}
}
