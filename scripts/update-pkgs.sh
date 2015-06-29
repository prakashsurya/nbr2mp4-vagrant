#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

#
# Return the error if the update fails.
#
sudo apt-get update -q || exit $?

sudo apt-get install -q -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    ubuntu-desktop bash

#
# Swallow the return code from `apt-get install` above. This is a hack,
# but it appears that some packages might fail to configure which cause
# a non-zero return code from `apt-get install`. It seems as though
# the desktop environment still works in the face of these error (no
# problems seen during brief testing); so we just swallow this error and
# return success. Otherwise, vagrant provisioning would catch the error
# code and halt the provisioning process.
exit 0
