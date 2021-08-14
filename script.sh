#! /bin/bash
# Original script by John Levine and Paul Hoffman (2013)
# [Ref] datatracker.ietf.org/doc/html/rfc7085
# Current version by Matheus Avellar (2021)
# Changes: no longer query for each nameserver, and individually for each
# record; instead we filter from a simple `host XX.` query.
# This may fail if a local address that collides with a TLD exists. For example,
# for a computer named "kiwi", the command `host kiwi.` will return the local IP
# However, the speed gain from not checking nameservers individually is 

mkdir _tmp
cd _tmp
echo "Getting list of current TLDs from IANA..."
wget -O TLDs.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

# As of 2021, gTLDs are prohibited from having apex A/AAAA or MX records
# Therefore, we can preemptively filter for only ccTLDs, as they're the only
# ones that could have such records
echo "Cleaning comments, and filtering only ccTLDs..."
grep -v '^#' TLDs.txt | grep -ixE '[a-z][a-z]' > ccTLDs.txt
# To check for ALL TLDs (not only country-code), use:
## grep -v '^#' TLDs.txt > ccTLDs.txt
# Warning: there are over 1 thousand TLDs. If you decide to not only check
# ccTLDs, the script will take ~1 hour to finish

# Count lines
total=$(wc -l ccTLDs.txt | awk '{ print $1 }')
echo "Found $total ccTLDs"

# Clear preliminar output file
echo "" > res.txt

echo "Querying ccTLDs..."
i=0
# For every ccTLD in the list
while read tld; do
  i=$((i+1))
  echo "$tld ($i/$total)"
  # Kill query if it doesn't finish after 5s
  timeout 5s host $tld. >> res.txt
done < ccTLDs.txt;

# Print and save the results
echo "" > ../dotless.txt
echo "Done!"
echo "A records ---------------------"                | tee -a ../dotless.txt
grep -iE "^[a-z]+ has address" res.txt     | sort -uf | tee -a ../dotless.txt
echo "AAAA records ------------------"                | tee -a ../dotless.txt
grep -iE "^[a-z]+ has IPv6" res.txt        | sort -uf | tee -a ../dotless.txt
echo "MX records --------------------"                | tee -a ../dotless.txt
grep -iE "^[a-z]+ mail is handled" res.txt | sort -uf | tee -a ../dotless.txt

# Clean up after ourselves
rm TLDs.txt ccTLDs.txt res.txt
cd ..
rmdir _tmp
