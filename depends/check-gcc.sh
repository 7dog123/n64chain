#!/bin/sh

## Check for gcc.
gcc --version 1> /dev/null || { echo "ERROR: Install gcc before continuing."; exit 1; }
