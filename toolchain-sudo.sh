#!/bin/bash

## Enter the ps2toolchain directory.
cd "`dirname $0`" || { echo "ERROR: Could not enter the ps2toolchain directory."; exit 1; }

## Set up the environment.
export N64=/opt
export PATH=$PATH:$N64/crashsdk/bin

## Run the toolchain script.
./toolchain.sh $@ || { echo "ERROR: Could not run the toolchain script."; exit 1; }
