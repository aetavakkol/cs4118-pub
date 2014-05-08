#!/bin/bash

# We must be run as root
if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    exit -1
fi

usage() { echo "Usage: $0 [-d <mount-directory>] [-m <module-directory>]" 1>&2; exit 1; }

banner="################################################################################"
banner2="----------------------------------------"
printBanner() {
	echo "$banner" >> "$resultFile"
	echo -e "$1\n$banner2" >> "$resultFile"
	eval "$1" >> "$resultFile" 2>&1
	echo "$banner" >> "$resultFile"
}

verifyCount() {
    lsOutput=$(ls -alF "$1")
    IFS=$'\n' lsArr=($lsOutput)
    pos="$2"
    line=$(echo "${lsArr[pos]}" | sed -e 's/ /\t/g')
    linkCount=$(echo "$line" | cut -f2)
    if [[ ! "$linkCount" == "$3" ]]; then
        echo "$banner" >> "$resultFile"
        echo "$1 has linkCount of $linkCount, instead of $3" >> "$resultFile"
        echo "$banner" >> "$resultFile"
    fi
}

while getopts ":m:d:" o; do
    case "${o}" in
        m)
            m=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        *)
			echo "Invalid option: -${OPTARG}" >&2
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ ! -z "$1" ]]; then
	usage
fi

# Get the mount directory
mntDir="${d:-mnt}"

# Delete the mntDir
umount "$mntDir" >/dev/null 2>&1
set -e
rm -rf "$mntDir"
set +e
mkdir "$mntDir"

resultFile="$PWD/part4-results.txt"
rm -rf "$resultFile"
# Make the module
initDir="$PWD"
makeDir="${m:-./}"
cd "$makeDir"
make clean 1>/dev/null 2>&1
set -e
printBanner "make"
cd "$initDir"

# Insert the module
set +e
rmmod lwnfs >/dev/null 2>&1
set -e
insmod "$makeDir/lwnfs.ko"
# Mount it
mount -t lwnfs none "$mntDir"
cd "$mntDir"
# Make a directory
mkdir heyBro
# Verify the count
verifyCount ./ 1 4
# Make another one
mkdir heyDog
# Verify the count again
verifyCount ./ 1 5

# Make a subdir
mkdir subdir/heyBrah
verifyCount subdir 1 3
# Make another subdir
mkdir subdir/heyDude
verifyCount subdir 1 4

# One final directory
mkdir subdir/heyDude/heyGirl
verifyCount subdir/heyDude 1 3

# Make sure the original count is still correct
verifyCount ./ 1 5

cd "$initDir"
umount "$mntDir"
rmmod lwnfs
set +e
