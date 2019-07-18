#!usr/bin/perl

#$dataDir = "/home/harsh/datasets/top8000/top8000_chains_70_merged";
#$dataDir = "/home/harsh/datasets/top8000/testSet_merged";
$dataDir = "../pdb";

opendir(DATADIR,$dataDir)||die "Can not open DATADIR.\n";

foreach $file(grep{m/.*\.pdb/}readdir(DATADIR))
{
	#print "Reading: $dataDir/$file\n";

###COPY FILES FROM DATA DIRECTORY AND RENAME THEM TO KEEP ONLY PDB ID.
###THIS IS BECAUSE PROMOTIF READS IT WRONGLY IF FILE NAME IS MORE THAN 4 LETTERS LONG EXCLUDING THE FILE EXTENSION.
	$file=~m/(....)(.+?)_?(.?)/;
	`cp $dataDir/$file $1.pdb`;
	#if(-e '$1.pdb'){print "*$1\n";}else{print "$1\n";}
	
}

###MAKE FILE LIST
print "Making file list : ls -d *.pdb>filelist\n";
`ls -d *.pdb>filelist`;

###RUN PROMOTIF IN MULTIPLE FILE MODE
print "Running promotif: ".`echo \$PID_PROMOTIF_PATH`."/promotif_multi.scr l filelist\n";
$promotifOutput = `\$PID_PROMOTIF_PATH/promotif_multi.scr l filelist`;

print $promotifOutput;

###DELETE UNWANTED FILES
print "Deleting unwanted files: rm *.pdb AND rm *.sst\n";
`rm *.pdb`;
`rm *.sst`;


