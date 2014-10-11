#!/usr/bin/perl

use warnings;
use strict;
use v5.10;

use CGI;

our @names;
open my $fh, "names-sample.txt" or die "$!";
while (<$fh>) {
	chomp;
	push @names, $_;
}
close $fh;

our @tokens;
open $fh, "tokens.txt" or die "$!";
while (<$fh>) {
	chomp;
	push @tokens, $_;
}
close $fh;

my $q = CGI->new;
print $q->header(-charset => 'utf-8');

print <<EOT;
<html><head>
 <title>brmelect Web Ballot</title>
 <style type="text/css">
  p, li { font-family: monospace; }
  #ballot { margin-left: auto; margin-right: auto; border: 1pt solid; width: 20em; padding: 1ex 1em; }
  .error { text-width: bold; color: red }
  #blurb { margin: 8ex 2em; }
 </style>
</head>
<body><h1 align="center">brmelect Web Ballot</h1>

<div id="blurb">

<p align="center">You can find your token on your paper ballot.<br />
<b style="color: darkred">Keep your token secret until the vote is closed!<br />
Udržujte svůj token v tajnosti, dokud není hlasování uzavřeno!</b></p>

<p>Enter preference numbers
for individual candidates.  You may skip some candidates (which you absolutely
do not wish to elect), but you must select at least one candidate. You must start
numbering your candidates with number 1, all candidates must have a unique
number and you must not skip any number.</p>

<p><a href="https://brmlab.cz/members/vnitrni-predpisy/sbrm/2011/5">2011/5 VII.8</a>: <em>Účastníci Valné hromady označí na volebních lístcích pořadí kandidátů připsáním čísla z nepřerušené řady přirozených čísel začínající jedničkou ke jménu kandidáta. Hlasovací lístek, který neobsahuje žádného označeného kandidáta nebo obsahuje alespoň dvě stejná čísla připsaná k různým kandidátům nebo takový, na kterém nejsou použita čísla z nepřerušené řady přirozených čísel, nebo žádný kandidát není označen číslem jedna, je neplatný.
</em></p>

<p>If you wish to cast an invalid vote, check the invalid ballot checkbox.</p>

<hr />

</div>

EOT


if ($q->param('go')) {
	my $token = $q->param('token');
	unless (grep { $_ eq $token } @tokens) {
		print qq#<p class="error">ERROR: Unknown token specified. Please go back and try again.</p>#;
		exit;
	}

	my $votestr;
	unless ($q->param('invalid')) {
		my @indices;
		for (0..@names) {
			$indices[$_] = '';
		}
		# XXX: We ignore $indices[0] for simplicity, we start indexing from 1 here!
		my %prefs;
		my $n_set = 0;

		for my $name (@names) {
			my $pref = $q->param($name);
			next unless ($pref);
			unless ($pref =~ /^\d+$/) {
				print qq#<p class="error">Preference for $name is $pref, which is not a number. Please go back and try again.</p>#;
				exit;
			}
			if ($indices[$pref] ne '') {
				print qq#<p class="error">Preference for $name is $pref, but this number is already also used for the candidate '$indices[$pref]'. Please go back and try again.</p>#;
				exit;
			}
			$indices[$pref] = $name;
			$prefs{$name} = $pref;
			$n_set++;
		}

		for my $i (1..$n_set) {
			if ($indices[$i] eq '') {
				print qq#<p class="error">Number $i was left unused, which is not permitted. Please go back and try again.</p>#;
				exit;
			}
		}
		for my $i (($n_set+1)..$#indices) {
			if ($indices[$i] ne '') {
				print qq#<p class="error">Number $i was used out of uninterrupted natural number sequence, which is not permitted. Please go back and try again.</p>#;
				exit;
			}
		}

		if ($indices[1] eq 0) {
			print qq#<p class="error">You must assign a preference (1) to at least one candidate. Please go back and try again.</p>#;
			exit;
		}

		$votestr = join(',', $token, map { $prefs{$_} or 0 } @names);
	} else {
		$votestr = join(',', $token, map { 'x' } @names);
	}

	print STDERR "$votestr\n";

	open $fh, '>>/home/pasky/votes.txt' or die "$!";
	print $fh "$votestr\n";
	close $fh;

	(my $rvotestr = $votestr) =~ s/^.*?,//;
	print qq#<p>Success.  Your vote ($rvotestr) has been saved.  You may still revise your vote before the closing call if you wish, but do NOT cast a paper ballot at this point anymore!</p>\n#;

	exit;
}

print <<EOT;
<form method="post">
<div id="ballot">
<p align="center"><b>Token:</b> <input type="text" name="token" size="5" maxlength="5" /></p>
<ul>
EOT

for my $name (@names) {
	print qq#<li><input type="text" name="$name" size="3" /> $name</li>\n#;
}

print <<EOT;
</ul>
<p align="center"><input type="checkbox" name="invalid" value="1" /> Produce <em>invalid</em> ballot</p>
</div>
<p align="center"><input type="submit" name="go" value="Submit Vote" /></p>
</form>

</body></html>
EOT
