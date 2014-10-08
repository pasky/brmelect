Generating Ballots
------------------

	./gen-ballot.pl 15 <names-sample.txt

Web Ballot CGI Script
---------------------

Put `names-sample.txt` and `tokens.txt` to the same directory as
`web-ballot.pl` and make that directory available for CGI script execution.
If this directory is accessible over web, don't forget to remove read
permissions for all but the owner.

It should just work; you may need to adjust the `votes.txt` path currently
hardcoded in `web-ballot.pl`, where the cast votes are recorded.
