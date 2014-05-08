# Homework 5 Grading Scripts #

*Ideas borrowed from Qinfan's Homework 4b Scripts*

## Extracting Submissions ##

1. Download the homework submissions (bulk_download.zip)
2. Run extract.sh
    - It takes 3 arguments: the path to split.txt, the path to buld_download.zip, and your name (as listed in split.txt).
        - An example: `./extract.sh ./split.txt ~/Downloads/buld_download.zip Mark`
    - It extracts the UNIs you've been assigned to into a directory called lwnfsbuild (under the currently working directory).
    - It also checks for things like binary files, proper directory structure, and being a git repo.

## Grading Submissions ##

- Some parts contain a static analysis portion; there's no script for those unfortunately.
- Part 2 is just looking at their submitted README.txt
- For part 1, 3, 4, and 5, the included scripts test all specified code points.
    - Each script has two optional options:
        - `-m`: The path to the students code (`Makefile`, in particular)
        - `-d`: The path to the mount directory
    - If not specified, the path to the students code defaults to the current directory, and the path to the mount directory defaults to `mnt` under the current directory.
    - Each script outputs the results of testing to part#-results.txt, which is created in the current directory.
- "No news is good news." Unless your VM crashes, the absence of messages in the part#-results.txt file means those tests were passed. Here's the output for part 4 produced with Jae's solution:

```
################################################################################
make
----------------------------------------
make -C /lib/modules/3.13.11-2-ck/build M=/home/mark/Documents/cs4118-ta/cs4118-pub/hw5-scripts/sol modules
make[1]: Entering directory '/usr/lib/modules/3.13.11-2-ck/build'
  CC [M]  /home/mark/Documents/cs4118-ta/cs4118-pub/hw5-scripts/sol/lwnfs.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /home/mark/Documents/cs4118-ta/cs4118-pub/hw5-scripts/sol/lwnfs.mod.o
  LD [M]  /home/mark/Documents/cs4118-ta/cs4118-pub/hw5-scripts/sol/lwnfs.ko
make[1]: Leaving directory '/usr/lib/modules/3.13.11-2-ck/build'
################################################################################
################################################################################
mkdir heyBro
----------------------------------------
################################################################################
################################################################################
mkdir heyDog
----------------------------------------
################################################################################
################################################################################
mkdir subdir/heyBrah
----------------------------------------
################################################################################
################################################################################
mkdir subdir/heyDude
----------------------------------------
################################################################################
################################################################################
mkdir subdir/heyDude/heyGirl
----------------------------------------
################################################################################
```

- The above output shows that all commands executed successfully. Not all commands produce output, but those that fail will output something indicating that they failed (unless the VM crashes, of course).
