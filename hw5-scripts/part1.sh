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

# Delete the mntDir
umount "$mntDir" >/dev/null 2>&1
set -e
rm -rf "$mntDir"
set +e
mkdir "$mntDir"

resultFile="$PWD/part1-results.txt"
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
printBanner "ls -alF"
printBanner "ls -alF subdir"
# Execute the session
commandOutput=("0" "1" "2" "" "1000000" "1000001" "1000002" "" "2000" "2001"
	"2002")
command=("cat counter" "cat counter" "cat counter" "echo 1000000 > counter"
	"cat counter" "cat counter" "cat counter" "echo 2000 > subdir/subcounter"
	"cat subdir/subcounter" "cat subdir/subcounter" "cat subdir/subcounter")

length=${#commandOutput[@]}
index=0
while [[ $index -lt $length ]]; do
    actualOutput=$(eval "${command[index]}")
    if [[ ! "$actualOutput" == "${commandOutput[index]}" ]]; then
        echo "$banner" >> "$resultFile"
        echo "${command[index]} mismatch:" >> "$resultFile"
        echo "$actualOutput" >> "$resultFile"
        echo "$banner" >> "$resultFile"
    fi
    index=$((index + 1))
done

cd "$initDir"
umount "$mntDir"
printBanner "ls -alF $mntDir"
rmmod lwnfs
set +e
