#!/bin/bash

if [[ $# -ne 3 ]]; then
	echo "usage: $0 <split.txt> <bulk_download.zip> <name>" >&2
	exit 1
fi

folderName="Homework 5"

# Look for the name in splits.txt
row=$(grep -m 1 "$3" "$1")
# Make sure the row is valid
if [[ -z "$row" ]]; then
	exit 2
fi

uniString="${row#*: }"
uniString="${uniString// /\|}"

# Unzip the archive
unzip "$2" >/dev/null
lwnfsDir="lwnfsbuild"
rm -rf ./"$lwnfsDir"
mv "$folderName" "$lwnfsDir"

# Delete non-matching folders
# Save the current folder
initDir="$PWD"
cd ./"$lwnfsDir"
for dir in ./*; do
	dirToDel=$(echo "$dir" | egrep -v "$uniString")
	# Delete the folder, if listed
	if [[ ! -z "$dirToDel" ]]; then
		rm -rf "$dirToDel"
	fi
done

extractFile="$initDir/extractResults.txt"
rm -rf "$extractFile"
touch "$extractFile"

# For the remaining folders
for dir in ./*; do
	tarFile=$(find "$dir" -type f -name "*.tar.gz")
	if [[ -z "$tarFile" ]]; then
		continue
	fi
	# Get the uni
	uni=$(echo "$tarFile" | egrep -o -m 1 "[[:alpha:]]{2,3}[[:digit:]]{3,4}")
	uni="${uni//
*/}"
	# Make a directory with their name
	uniDir="lwnfs-$uni"
	mkdir "$uniDir"
	tarDir="$PWD"
	cd "$uniDir"
	tar xf "$tarDir/$tarFile"
	file=$(ls)
	# Correct directory structure
	if [[ "$file" = "$uniDir" ]]; then
		shopt -s dotglob
		mv "$file"/* ./
		rm -rf "$file"
		shopt -u dotglob
	else
		echo "$uni: incorrect directory structure" >> "$extractFile"
	fi
	# Check for git
	gitFile=$(ls -a | grep "\.git")
	if [[ ! "$gitFile" == *.git* ]]; then
		echo "$uni: not a git directory" >> "$extractFile"
	fi
	# Check for binary files
	binaryFiles=$(grep -r -m 1 "^" "$PWD" | grep -v "\.git" | grep "^Binary file")
	if [[ ! -z "$binaryFiles" ]]; then
		echo "$uni: binary files found:" >> "$extractFile"
		echo "$binaryFiles" >> "$extractFile"
		# Remove the binary files
		IFS=$'\n' binArr=($binaryFiles)
		for binStr in "${binArr[@]}"; do
			binFile="${binStr#Binary file }"
			binFile="${binFile% matches}"
			rm -rf "$binFile"
		done
	fi
	cd "$tarDir"
	# Remove the old directory
	rm -rf "$dir"
done
cd "$initDir"
