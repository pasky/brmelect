#!/usr/bin/perl

use warnings;
use strict;
use v5.10;

use CGI;

my $votefile = '/home/pasky/votes.txt';

our @names;
open my $fh, "names.txt" or die "$!";
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
  table { margin-left: auto; margin-right: auto; border: 1pt solid; border-collapse: collapse; }
  td { border: 1pt solid; padding: 0.5ex 0.5em; }
 </style>
</head>
<body><h1 align="center">brmelect Web Ballot</h1>

<div id="blurb">

<p align="center">You can find your token on your paper ballot.<br />
<b style="color: darkred">Keep your token secret until the vote is closed!<br />
Udržujte svůj token v tajnosti, dokud není hlasování uzavřeno!</b></p>

<p align="center">Sort individual candidates by preference.<br />
If you do not wish to elect some candidates at all, do not assign any preference to them.<br />
Do not leave any gaps in the preferences.</p>

<!--<p><a href="https://brmlab.cz/members/vnitrni-predpisy/sbrm/2011/5">2011/5 VII.8</a>: <em>Účastníci Valné hromady označí na volebních lístcích pořadí kandidátů připsáním čísla z nepřerušené řady přirozených čísel začínající jedničkou ke jménu kandidáta. Hlasovací lístek, který neobsahuje žádného označeného kandidáta nebo obsahuje alespoň dvě stejná čísla připsaná k různým kandidátům nebo takový, na kterém nejsou použita čísla z nepřerušené řady přirozených čísel, nebo žádný kandidát není označen číslem jedna, je neplatný.
</em></p>-->

<!-- <p>If you wish to cast an invalid vote, check the invalid ballot checkbox.</p> -->

<hr />

</div>

EOT


if ($q->param('inspect')) {
	my $token = $q->param('token');
	unless (grep { $_ eq $token } @tokens) {
		print qq#<p class="error">ERROR: Unknown token specified. Please go back and try again.</p>#;
		exit;
	}

	my %votes;
	open my $fh, $votefile or die "$!";
	while (<$fh>) {
		chomp;
		my @b = split/,/;
		$votes{$b[0]} = [@b];
	}
	close $fh;
	if (not $votes{$token}) {
		print qq#<p>No vote for this (valid) token has been cast.</p>#;
		exit;
	} else {
		my @vote = @{$votes{$token}};
		shift @vote;
		print "<table>\n";
		for my $i (0..$#names) {
			print "<tr><td>".$names[$i]."</td><td>".$vote[$i]."</td></tr>\n";
		}
		print "</table>\n";
	}
	exit;
}


if ($q->param('submit')) {
	my $token = $q->param('token');
	unless (grep { $_ eq $token } @tokens) {
		print qq#<p class="error">ERROR: Unknown token specified. Please go back and try again.</p>#;
		exit;
	}

	my $votestr;
	unless ($q->param('invalid')) {
		my @indices;
		# XXX: We ignore $indices[0] for simplicity, we start indexing from 1 here!
		my %prefs;
		my $n_set = 0;

		my $over = 0;
		for my $i (1..@names) {
			my $pref = $q->param($i);
			if (not defined $pref or $pref eq '') {
				$over = 1;
				next;
			}
			if ($over > 0) {
				print qq#<p class="error">Number $i has a candidate but some higher preference does not, which is not permitted. Please go back and try again.</p>#;
				exit;
			}
			if (not grep { $_ eq $pref } @names) {
				print qq#<p class="error">Number $i has an unknown candidate $pref, are you trolling? Please go back and try again.</p>#;
				exit;
			}
			if (exists $prefs{$pref}) {
				print qq#<p class="error">Candidate $pref is selected as both number $prefs{$pref} and $i, this is not permitted. Please go back and try again.</p>#;
				exit;
			}
			$prefs{$pref} = $i;
			$indices[$i] = $pref;
		}

		if (not keys %prefs) {
			print qq#<p class="error">You must assign a preference to at least one candidate. Please go back and try again.</p>#;
			exit;
		}

		$votestr = join(',', $token, map { $prefs{$_} or 0 } @names);
	} else {
		$votestr = join(',', $token, map { 'x' } @names);
	}

	print STDERR "$votestr\n";

	open $fh, '>>' . $votefile or die "$!";
	print $fh "$votestr\n";
	close $fh;

	(my $rvotestr = $votestr) =~ s/^.*?,//;
	print qq#<p>Success.  Your vote ($rvotestr) has been saved.</p> <p>You may still revise your vote before the closing call if you wish, but do NOT cast a paper ballot at this point anymore!</p>\n#;

	exit;
}

print <<EOT;
<form method="post">
<div id="ballot">
<p align="center"><b>Token:</b> <input type="password" name="token" size="5" maxlength="5" />
(<input type="submit" name="inspect" value="Inspect Vote" />)</p>
</p>
<ul>
EOT

for my $i (1..@names) {
	my $options = join('', map { qq#<option value="$_">$_</option># } @names);
	print qq#<li>$i. <select name="$i"><option value="" selected="1">- - -</option>$options</select></li>\n#;
}

print <<EOT;
</ul>
<!-- <p align="center"><input type="checkbox" name="invalid" value="1" /> Produce <em>invalid</em> ballot</p> -->
</div>
<p align="center"><input type="submit" name="submit" value="Submit Vote" /></p>
</form>

</body></html>
EOT
