#! /bin/bash
# Original script by John Levine and Paul Hoffman (2013)
# [Ref] datatracker.ietf.org/doc/html/rfc7085
# Current version by Matheus Avellar (2025)
# Changes: no longer query for each nameserver, and individually for each
# record; instead we filter from a simple `host XX.` query.
# This may fail if a local address that collides with a TLD exists. For example,
# for a computer named "kiwi", the command `host kiwi.` will return the local IP
# There may be additional unknown and unintended consequences. However, the
# speed gain is significant enough to justify the changes.

mkdir _tmp
cd _tmp
echo "Getting list of current TLDs from IANA..."
wget -O _rawTLDs.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

grep -v '^#' _rawTLDs.txt > _TLDs.txt

# Count lines
total=$(wc -l _TLDs.txt | awk '{ print $1 }')
echo "Found $total TLDs"

# Clear preliminar output file
echo "" > _results.txt

echo "Querying TLDs..."
i=0
# For every ccTLD in the list
while read tld; do
	i=$((i+1))
	echo "$tld ($i/$total)"
	# Kill query if it doesn't finish after 15s
	timeout 15s host $tld. >> _results.txt
done < _TLDs.txt;

# Print and save the results
touch ../dotless.txt
echo "Done!"
echo "A records ---------------------"                | tee -a ../dotless.txt
grep -iE "^[A-Za-z0-9\-]+ has address" _results.txt     | sort -uf | tr '[:upper:]' '[:lower:]' | tee -a ../dotless.txt
echo "AAAA records ------------------"                | tee -a ../dotless.txt
grep -iE "^[A-Za-z0-9\-]+ has IPv6" _results.txt        | sort -uf | tr '[:upper:]' '[:lower:]' | tee -a ../dotless.txt
echo "MX records --------------------"                | tee -a ../dotless.txt
grep -iE "^[A-Za-z0-9\-]+ mail is handled" _results.txt | sort -uf | tr '[:upper:]' '[:lower:]' | tee -a ../dotless.txt

# Clean up after ourselves
rm _rawTLDs.txt _TLDs.txt _results.txt
cd ..
rmdir _tmp
