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

printAndVerify() {
    echo "$banner" >> "$resultFile"
    echo -e "$1\n$banner2" >> "$resultFile"
    eval "$1" >> "$resultFile" 2>&1
    count=$(cat "$2")
    if [[ ! "$count" == "$3" ]]; then
        echo "Counter value of $count, instead of $3" >> "$resultFile"
    fi
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
mntDir="$PWD/$mntDir"

# Delete the mntDir
umount "$mntDir" >/dev/null 2>&1
set -e
rm -rf "$mntDir"
set +e
mkdir "$mntDir"

resultFile="$PWD/part5-results.txt"
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
printBanner "mkdir heyBro"
# Make a counter
printBanner "touch myCounter"
# Verify the link count
verifyCount ./myCounter 0 1
# Verify counter functionality
printAndVerify "echo 1000 > myCounter" myCounter 1000
# Make another counter
printAndVerify "echo 1000 > anotherCounter" anotherCounter 1000

# Touch a counter
printAndVerify "touch heyBro/aCounter" heyBro/aCounter 0
# Verify it again
printAndVerify "touch heyBro/aCounter" heyBro/aCounter 1
# Verify the link count
verifyCount heyBro/aCounter 0 1

cd "$initDir"
umount "$mntDir"
rmmod lwnfs
set +e
