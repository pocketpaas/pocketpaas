#!/bin/bash

# TODO check for carton and fall back to system version of perltidy if not
# found.  make sure perltidy version is 20130806

for file in `./.ack -f --perl --ignore-file=is:.ack --ignore-dir local`; do
    echo "Tidying $file";
    carton exec perltidy -pro=.../.perltidyrc $file;
done
