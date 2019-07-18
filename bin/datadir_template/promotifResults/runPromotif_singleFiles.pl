#!usr/bin/perl

$dataDir = "../pdb";

opendir(DATADIR,$dataDir)||die "Can not open DATADIR.\n";

foreach $file(grep{m/.*\.pdb/}readdir(DATADIR))
{
	print "Running promotif: ".`echo \$PID_PROMOTIF_PATH`."/promotif.scr $dataDir/$file\n";
	`\$PID_PROMOTIF_PATH/promotif.scr $dataDir/$file`;
	`rm *.ps *.sum`;
}

closedir(DATADIR);

###JOIN	ALL .blg FILES TO MAKE A SINGLE BULGE FILE.
print "\nJoining all .blg files in to one BULGES file.\n\n";
open(BULGES,">BULGES")||die"Can not open BULGE for writing.\n";

opendir(DIR,".")||die "Can not open DIR.\n";

foreach $file(grep{s/(.+)\.blg$/$1/}readdir(DIR))
{
	open(BLG,"$file.blg")||print"Can not open BLG.\n";
	foreach $line(<BLG>)
	{
		print BULGES "$file $line";
	}
	close(BLG);
}

closedir(DATADIR);
close(BULGES);

