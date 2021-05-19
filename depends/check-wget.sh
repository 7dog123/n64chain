#!/bin/sh

## Check for wget.
wget -V 1> /dev/null || { echo "ERROR: Install wget before continuing."; exit 1; }
