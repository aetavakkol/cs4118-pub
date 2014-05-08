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

resultFile="$PWD/part3-results.txt"
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
printBanner "echo mounted!"
cd "$mntDir"
# Get the output
lsOutput=$(ls -alF)
IFS=$'\n' lsArr=($lsOutput)
# The second line is the root directory, which has a link count of 3
line=$(echo "${lsArr[1]}" | sed -e 's/ /\t/g')
linkCount=$(echo "$line" | cut -f2)
if [[ ! "$linkCount" == "3" ]]; then
    echo "$banner" >> "$resultFile"
    echo "Root directory has linkCount of $linkCount, instead of 3" >> "$resultFile"
    echo "$banner" >> "$resultFile"
fi
# The fourth line is counter, which has a link count of 1
line=$(echo "${lsArr[3]}" | sed -e 's/ /\t/g')
linkCount=$(echo "$line" | cut -f2)
if [[ ! "$linkCount" == "1" ]]; then
    echo "$banner" >> "$resultFile"
    echo "counter has linkCount of $linkCount, instead of 1" >> "$resultFile"
    echo "$banner" >> "$resultFile"
fi
# The fifth line is subdir, which has a link count of 2
line=$(echo "${lsArr[4]}" | sed -e 's/ /\t/g')
linkCount=$(echo "$line" | cut -f2)
if [[ ! "$linkCount" == "2" ]]; then
    echo "$banner" >> "$resultFile"
    echo "subdir has linkCount of $linkCount, instead of 2" >> "$resultFile"
    echo "$banner" >> "$resultFile"
fi
# Now check subcounter
lsOutput=$(ls -alF ./subdir)
IFS=$'\n' lsArr=($lsOutput)
# The fourth line is subcounter, which has a link count of 1
line=$(echo "${lsArr[3]}" | sed -e 's/ /\t/g')
linkCount=$(echo "$line" | cut -f2)
if [[ ! "$linkCount" == "1" ]]; then
    echo "$banner" >> "$resultFile"
    echo "subcounter has linkCount of $linkCount, instead of 1" >> "$resultFile"
    echo "$banner" >> "$resultFile"
fi
cd "$initDir"
umount "$mntDir"
rmmod lwnfs
set +e
