#!/bin/sh
# Given a single argument copies it over to /tmp using the name resolved by pwd.

# If there are no arguments, quit
if [ -z "$1" ]; then
    echo "usage: $0 dir"
    exit 1
fi

# Make sure the /tmp directory is on a tmpfs
suppress="$(mount | grep tmpfs | grep /tmp)"
if [ "$?" -ne 0 ]; then
    echo "/tmp is not on a tmpfs"
    exit 2
fi

# Make sure the /tmp directory is rw
if [ ! -r /tmp -a ! -w /tmp ]; then
    echo "/tmp is not read-writable"
    exit 3
fi

dir_arg=$1
# Make sure we were given a directory
if [ ! -d "$dir_arg" ]; then
    echo "$dir_arg: is not a directory."
    exit 4
fi

# Mark the directory we started in
orig_dir="$CWD"

# Resolve the directory given to a name
dir="$(realpath "$dir_arg")"
dir_name="${dir##*/}"

# Move to the tmp folder
cd /tmp
# Make the directory
mkdir "$dir_name"
# Change that directory
cd "$dir_name"

# Replicate the directory structure
## Generate a list of all folders in the original directory
folders="$(find "$dir" -type d)"
## Retrieve the path of the original directory from find itself
base_dir="${folders%%$'\n'*}/"
## Remove this listing from the list of all folders (find includes the original directory)
folders="${folders#*$'\n'}"
## Generate a list of folders with the prefix of the original directory removed
rel_folders="${folders//$base_dir/}"
## Pass the list to mkdir
echo "$rel_folders" | xargs mkdir

# Convert rel_folders to a file array
IFS=$'\n' file_arr=($rel_folders)
# Copy the top-levels original files
for file in $base_dir/*
do
    if [ ! -d "$file" ]; then
        ln -s "$file"
    fi
done

# Mark the top-level directory
top_dir="$(pwd)"
# Loop through each folder
for tmp_dir in "${file_arr[@]}"
do
    # cd to that folder
    cd "$tmp_dir"
    # iterate through the folders at the original location
    for file in $base_dir/$tmp_dir/*
    do
        # Symlink non-directories
        if [ ! -d "$file" ]; then
            ln -s "$file"
        fi
    done
    # move back to the top level directory
    cd "$top_dir"
done

# Move back to the original directory
cd "$orig_dir"

echo done

