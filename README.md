Initialization
--------------

Decide on label of the election.  We will refer to that as `$label`;
this label is to be passed as a parameter to `gen-ballot.pl` and
updated near the top of `web-ballot.pl`.  The generated `votes.txt`
file contains this in its filename.

Copy `names-sample.txt` to `names.txt` or create your own `names.txt`.
Clobber your `~/votes $label.txt` file.

Generating Ballots
------------------

	./gen-ballot.pl 15 "testovaci komise" <names.txt >tokens.txt

Web Ballot CGI Script
---------------------

Put `names.txt` and `tokens.txt` to the same directory as
`web-ballot.pl` and make that directory available for CGI script execution.
If this directory is accessible over web, don't forget to remove read
permissions for all but the owner.

After updating the "$label" setting in web-ballot.pl,
it should just work; you may need to adjust the `votes.txt` path currently
hardcoded in `web-ballot.pl`, where the cast votes are recorded.

Counting Votes
--------------

This script will show just the final vote for each token:

	perl -nle 'chomp; @b = split/,/; $a{$b[0]} = [@b]; END { for (values %a) { print join(",", @$_); } }' ~/'votes testovaci komise'.txt >finalvotes.txt

Append votes from collected paper ballots, one line per ballot, with numbers
for each candidate as entered (use 0 in place of numbers not entered for
a particular candidate).

Then, build input for `hlas.pl` - a text file, that has:

	NUMBER_OF_ELECTED_CANDIDATES  (1 for predseda, 3 or 5 or 7 for rada, ...)
	<names.txt>

	<cat finalvotes.txt | cut -d, -f 2- | tr , ' '>

	0

(See hlas-example.txt for an example.)

Then, run `hlas.pl < textfile` and there you go!
