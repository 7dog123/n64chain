#!/bin/sh

## Check for texinfo.
makeinfo --version 1> /dev/null || { echo "ERROR: Install gcc before continuing."; exit 1; }
