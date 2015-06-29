#!/bin/bash

set -o errexit
set -o nounset

#
# The following file was downloaded via this URL:
#
#     http://support.webex.com/supportutilities/nbr2mp4.tar
#
# While we could have downloaded that file directly from within this
# script, that would introduce a possible point of failure should that
# link happen to change or become inaccessible. Thus, the file was
# downloaded and archived within the repository, and we access it via
# the synced folder.
#
NBR2MP4_TAR="/vagrant/archive/nbr2mp4.tar"

#
# This is the directory we use to extract/install the nbr2mp4 utility.
#
NBR2MP4_DIR="$HOME/nbr2mp4"

#
# Download the conversion utility.
#
# The following instructions were taken from the "NBR2MP4" section of the
# following web page: https://www.webex.co.uk/support/downloads.html
#
cd ~
if [[ ! -e "$NBR2MP4_DIR" ]]; then

	#
	# Double check the tar archive exists in the expected location.
	#
	[[ ! -f "$NBR2MP4_TAR" ]] && exit 2

	tar -xvf "$NBR2MP4_TAR"
	chmod +x ./nbr2mp4.sh
	echo "$NBR2MP4_DIR" | ./nbr2mp4.sh
fi

function convert_to_mp4
{
	local arf_filename="$1"
	local mp4_filename="$2"

	#
	# The utility doesn't work when passing in the "mp4" vagrant
	# synced folder directly, so as a workaround we create a
	# temporary directory to use.
	#
	tmp=$(mktemp -dt vagrant-nbr2mp4-XXXXXXXXXX)

	#
	# Run the conversion utility.
	#
	"$NBR2MP4_DIR/nbr2_mp4/nbr2mp4" "$arf_filename" "$tmp"

	#
	# Some basic sanity checking. We only expect the nbr2mp4 utility
	# to create a single output file, so ensure there's only a
	# single one contained in the temporary directory we created.
	#
	# Keep in mind, we're not cleaning up the temporary directory
	# and/or files in the directory to try and make debugging
	# easier; thus, the directory will need to be removed manually.
	#
	[[ "$(find "$tmp" -type f | wc -l)" -ne "1" ]] &&
	    return 2

	#
	# Copy the output files to their final output directory (we've
	# already verified this command will only output a single file).
	#
	cp "$(find "$tmp" -type f)" "$mp4_filename"

	#
	# remove the temporary directory we created above.
	#
	rm -rf "$tmp"

	return 0
}

function convert_to_mp3
{
	local arf_filename="$1"
	local mp3_filename="$2"

	#
	# To try and keep any incomplete MP3 files due to failed
	# conversions out of the final output directory, we first
	# convert to a temporary file. Then, once the conversion
	# successfully finishes, we copy the file to it's final home.
	#
	tmp_mp3=$(mktemp -t vagrant-nbr2mp3-XXXXXXXXXX)

	#
	# For some reason, the utility needs an extran temporary file
	# to be passed in as it's third argument. Thus we create another
	# temporary file to use with it.
	#
	tmp_extra=$(mktemp -t vagrant-nbr2mp3-XXXXXXXXXX)

	#
	# Run the conversion utility.
	#
	"$NBR2MP4_DIR/nbr2_mp4/nbr2mp3" "$arf_filename" "$tmp_mp3" "$tmp_extra"

	#
	# Copy the output files to their final output directory (we've
	# already verified this command will only output a single file).
	#
	cp "$tmp_mp3" "$mp3_filename"

	#
	# remove the temporary files we created above.
	#
	rm -f "$tmp_mp3" "$tmp_extra"

	return 0
}

#
# Run the conversion utility across all files, careful to skip over
# files that have already been converted. The input directory that is
# inspected for files to convert is "/vagrant/arf", this should map to
# the top level "arf" directory on the host system (we're relying on
# Vagrant's synced folder functionality). The converted videos will be
# placed in "/vagrant/mp4", which should map to the top level "mp4"
# directory on the host system.
#

ARF_DIRECTORY="/vagrant/arf"
MP4_DIRECTORY="/vagrant/mp4"
MP3_DIRECTORY="/vagrant/mp3"

ARF_EXTENSION=".arf"
MP4_EXTENSION=".mp4"
MP3_EXTENSION=".mp3"

#
# The nbr2mp4 utility needs to connect to the X display in order to
# function. The previous vagrant provision scripts should have set up
# the system such that the vagrant user is logged into the X
# environment, and we're attempting to use that environment here.
#
export DISPLAY=":0"

#
# We need to be careful since the filenames may (and probably will)
# contain spaces; thus, we use find and read here.
#
find "$ARF_DIRECTORY" -type f | while read arf_filename; do
	#
	# The directory containing the ARF files also contains a single
	# README file, we need to be sure to skip this file.
	#
	[[ "$(basename $arf_filename)" = "README" ]] && continue

	base=$(basename "$arf_filename" "$ARF_EXTENSION")

	#
	# If we couldn't extract the base filename using the expected
	# extension, abort.
	#
	[[ -z "$base" ]] && exit 2

	mp4_filename="${MP4_DIRECTORY}/${base}${MP4_EXTENSION}"
	mp3_filename="${MP3_DIRECTORY}/${base}${MP3_EXTENSION}"

	#
	# If the MP4 or MP3 file for this ARF file already exists, this
	# video must have been already converted; skip that conversion.
	#

	#
	# MP4 conversion is disabled, this doesn't seem to work yet.
	#
	# [[ -e "$mp4_filename" ]] || \
	#     convert_to_mp4 "$arf_filename" "$mp4_filename"

	[[ -e "$mp3_filename" ]] || \
	    convert_to_mp3 "$arf_filename" "$mp3_filename"
done
