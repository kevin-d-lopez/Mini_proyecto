# Make sure to run this script from the project's root directory.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\build.ps1 

### Script Configuration ###
$project_name = "CoinRunner"

$ca65_path = "ca65"
$ld65_path = "ld65"

# If ca65 is NOT in the system PATH, uncomment the line below and modify the
# path to the ca65 binary accordingly.
# $ca65_path = (Resolve-Path (Join-Path (Get-Location) "..\..\..\cc65-snapshot-win64\bin\ca65.exe")).Path

# If ld65 is NOT in the system PATH, uncomment the line below and modify the
# path to the ld65 binary accordingly.
# $ld65_path = (Resolve-Path (Join-Path (Get-Location) "..\..\..\cc65-snapshot-win64\bin\ld65.exe")).Path

### Start Script ###

# Get the working directory path
$dir = Get-Location

# Assemble the main file (i.e., src\main.asm)
$main_path = "$dir\src\main.asm"
if (-not (Test-Path $main_path)) {
  Write-Host "ERROR: Main file was not found at: $main_path"
  exit 1
} else {
  & $ca65_path -I "include" -o "$dir\main.o" $main_path
  Write-Host "Finished assembling $main_path"
}

# Assemble the reset file (i.e., src\reset.asm)
$reset_path = "$dir\src\reset.asm"
if (-not (Test-Path $reset_path)) {
  Write-Host "ERROR: Reset file was not found at: $reset_path"
  exit 1
} else {
  & $ca65_path -I "include" -o "$dir\reset.o" $reset_path
  Write-Host "Finished assembling $reset_path"
}

# Link object files and create .nes file
& $ld65_path -C nes.cfg -o "$dir\$project_name.nes" "$dir\main.o" "$dir\reset.o"
Write-Host "Finished linking files, and producing .nes file"

# Delete object files
Remove-Item "$dir\main.o"
Remove-Item "$dir\reset.o"
Write-Host "Done"
