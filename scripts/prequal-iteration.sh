#!/bin/bash

# run_prequal.sh
#
# Description: Run prequal to remove offending sequences
# That is, run iteratively until no more sequences
# with proportion of filtered sites >25%.
#
# Usage: ./run_prequal.sh infile.fasta
#
# Version: Thu 25 Jan 2018 11:00:36 AM CET
#
# By: Johan.Nylander\@{nrm|nbis}.se


#set -euo pipefail

hash prequal 2>/dev/null || { echo >&2 "I require prequal but it's not installed in PATH.  Aborting."; exit 1; }
prequal=$(which prequal)

hash grepfasta.pl 2>/dev/null || { echo >&2 "I require grepfasta.pl but it's not installed in PATH.  Aborting."; exit 1; }
grepfasta=$(which grepfasta.pl)

if [[ $# -eq 0 ]] ; then
    echo "Usage: ./$0 fasta.file"
    exit 0
else
    infile="$1"
    if [ ! -e "$infile" ]; then
        echo "File $infile not found."
        exit
    fi
fi

i=0

fastafile="${infile}.${i}"

if [ -e "$fastafile" ] ; then
    echo "File $fastafile already exists. Exiting"
else
    ln -s "${infile}" "$fastafile"
fi

echo ""
echo -n "#### "
date
echo "#### Run prequal on $infile"

$prequal "$fastafile" &>/dev/null

WarningFile="${fastafile}.warning"
WarningsFile="${infile}-prequal-warnings.txt"

if [ -e "$WarningFile" ]; then
    j=0
    while true ; do
        warnfile=$(find . -maxdepth 1 -name \*.warning -print)
        problemlistfile="${fastafile}.problematic.${i}.seqids"
        grep 'sequence removed' "$warnfile" | awk '{print $2}' > "$problemlistfile"
        if [ ! -s "$problemlistfile" ]; then
            rm "$problemlistfile"
            break
        fi
        cat "$warnfile" >> "$WarningsFile"
        rm "$warnfile"
        ((j++))
        newfastafile=${fastafile%.[0-9]*}.${j}
        $grepfasta -v -f "$problemlistfile" "$fastafile" > "$newfastafile"
        echo "#### Found problematic sequences:"
        cat "$problemlistfile"
        echo ""
        echo "#### Run prequal again on file $newfastafile"
        $prequal "$newfastafile" &>/dev/null
        ((i++))
        fastafile="$newfastafile"
    done
fi

if [ -e "${fastafile}.dna.filtered" ]; then
    cp "${fastafile}.dna.filtered" "${infile}-prequal-dna.fas"
    Nf=$(grep -c '>' ${infile}-dna-filtered.fas)
fi
if [ -e "${fastafile}.filtered" ]; then
    cp "${fastafile}.filtered" "${infile}-prequal.fas"
    Nf=$(grep -c '>' ${infile}-filtered.fas)
fi
if [ -e "${fastafile}.filtered.PP" ]; then
    cp "${fastafile}.filtered.PP" "${infile}-prequal-PP.txt"
fi
if [ -e "${fastafile}.translation" ]; then
    cp "${fastafile}.translation" "${infile}-prequal-translation.txt"
fi

Nuf=$(grep -c '>' ${infile})
nr=$((Nuf-Nf))

rm ${infile}.*

echo -n "#### "
date
echo "#### End of script"
echo "#### $nr (out of $Nuf) sequences removed (see $WarningsFile)"
echo "#### Filtered file: ${infile}-dna-filtered.fas or ${infile}-filtered.fas"
echo ""


