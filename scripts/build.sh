#!/bin/bash

# Make sure to run this script from the project's root directory.
# Usage: ./scripts/build.sh 

### Script Configuration ###
project_name="CoinCollector"

ca65_path="ca65"
ld65_path="ld65"

# If ca65 is NOT in the system PATH, uncomment the line below and modify the
# path to the ca65 binary accordingly.
# ca65_path="$(realpath ../../../cc65-snapshot-win64/bin/ca65)"

# If ld65 is NOT in the system PATH, uncomment the line below and modify the
# path to the ld65 binary accordingly.
# ld65_path="$(realpath ../../../cc65-snapshot-win64/bin/ca65)"

### Start Script ###

# Get the working directory path
dir="$PWD"

# Assemble the main file (i.e., src/main.asm)
main_path="src/main.asm"
if ! [[ -f "$main_path" ]]
then
  echo "ERROR: Main file was not found at: $main_path"
  exit 1
else
  "$ca65_path" -I "include" -o "$dir/main.o" $main_path
  echo "Finished assembling $main_path"
fi

# Assemble the reset file (i.e., src/reset.asm)
reset_path="src/reset.asm"
if ! [[ -f "$reset_path" ]]
then
  echo "ERROR: Reset file was not found at: $reset_path"
  exit 1
else
  "$ca65_path" -I "include" -o "$dir/reset.o" $reset_path
  echo "Finished assembling $reset_path"
fi

# Link object files and create .nes file
"$ld65_path" -C nes.cfg -o "$dir/$project_name.nes" "$dir/main.o" "$dir/reset.o" 
echo "Finished linking files, and producing .nes file"

# Delete object files
rm "$dir/main.o"
rm "$dir/reset.o"
echo "Done"
