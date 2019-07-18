#!bin/bash

cd bin/

#echo "$1"
#echo "$2"
perl buildPdbInteractionTables_serial.pl --file "$1" > "$2"


