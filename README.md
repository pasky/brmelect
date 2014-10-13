Initialization
--------------

Copy `names-sample.txt` to `names.txt` or create your own `names.txt`.
Clobber your `~/votes.txt` file.

Generating Ballots
------------------

	./gen-ballot.pl 15 <names.txt >tokens.txt

Web Ballot CGI Script
---------------------

Put `names.txt` and `tokens.txt` to the same directory as
`web-ballot.pl` and make that directory available for CGI script execution.
If this directory is accessible over web, don't forget to remove read
permissions for all but the owner.

It should just work; you may need to adjust the `votes.txt` path currently
hardcoded in `web-ballot.pl`, where the cast votes are recorded.

Counting Votes
--------------

This script will show just the final vote for each token:

	perl -nle 'chomp; @b = split/,/; $a{$b[0]} = [@b]; END { for (values %a) { print join(",", @$_); } }' ~/votes.txt
