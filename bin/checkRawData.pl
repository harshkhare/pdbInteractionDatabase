#!usr/bin/perl

$rawDataDir = $ARGV[0];

$hbplusDir = $rawDataDir."/pdbHbplus";
$cleanDir = $rawDataDir."/pdbClean";
$pdbDir = $rawDataDir."/pdb";
$dsspDir = $rawDataDir."/pdbDssp";
$naccessDir = $rawDataDir."/pdbNaccess";
$pdb_originalDir = $rawDataDir."/pdbOriginal";
$promotifResultsDir = $rawDataDir."/promotifResults";
$probeDir = $rawDataDir."/pdbProbe";


opendir(HBPLUSDIR,$hbplusDir)||die"Can not open HBPLUSDIR.\n";
@hbplusFiles = grep{m/\.hb2$/}readdir(HBPLUSDIR);
close(HBPLUSDIR);

opendir(CLEANDIR,$cleanDir)||die"Can not open CLEANDIR.\n";
@cleanFiles = grep{m/\.pdb$/}readdir(CLEANDIR);
close(CLEANDIR);

opendir(PDBDIR,$pdbDir)||die"Can not open PDBDIR.\n";
@pdbFiles = grep{m/\.pdb$/}readdir(PDBDIR);
close(PDBDIR);

opendir(DSSPDIR,$dsspDir)||die"Can not open DSSPDIR.\n";
@dsspFiles = grep{m/\.dssp$/}readdir(DSSPDIR);
close(DSSPDIR);

opendir(PROBEDIR,$probeDir)||die"Can not open PROBEDIR.\n";
@probeFiles = grep{m/\.probe$/}readdir(PROBEDIR);
close(PROBEDIR);

opendir(NACCESSDIR,$naccessDir)||die"Can not open NACCESSDIR.\n";
@asaFiles = grep{m/\.asa$/}readdir(NACCESSDIR); rewinddir(NACCESSDIR);
@rsaFiles = grep{m/\.rsa$/}readdir(NACCESSDIR); rewinddir(NACCESSDIR);
@logFiles = grep{m/\.log$/}readdir(NACCESSDIR); rewinddir(NACCESSDIR);
@asacFiles = grep{m/\.asac$/}readdir(NACCESSDIR); rewinddir(NACCESSDIR);
@rsacFiles = grep{m/\.rsac$/}readdir(NACCESSDIR); rewinddir(NACCESSDIR);
@logcFiles = grep{m/\.logc$/}readdir(NACCESSDIR);
close(DSSPDIR);

$originalDirFlag = 0;
@pdb_originalFiles = ();
if(-d $pdb_originalDir)
{
	opendir(PDB_ORIGINALDIR,$pdb_hDir)||die"Can not open PDB_ORIGINALDIR.\n";
	@pdb_originalFiles = grep{m/\.pdb$/}readdir(PDB_ORIGINALDIR);
	close(PDB_ORIGINALDIR);
	$originalDirFlag = 1;
}

opendir(PROMOTIFDIR,$promotifResultsDir)||die"Can not open PROMOTIFDIR.\n";
@promotifResultsFiles = readdir(PROMOTIFDIR);
close(PROMOTIFDIR);


###CHECK 1: CHECK FOR MISSING FILES IN ANY DIRECTORIES.
$check1Pass = 0;
print "\nCHECK 1: CHECK FOR MISSING FILES.\n\n";
if(
		(@pdbFiles==@dsspFiles &&	 @pdbFiles==@hbplusFiles &&	 @pdbFiles==@cleanFiles && @pdbFiles==@asaFiles && @pdbFiles==@rsaFiles && @pdbFiles==@logFiles && @pdbFiles==@asacFiles && @pdbFiles==@rsacFiles && @pdbFiles==@logcFiles && @pdbFiles==@probeFiles) &&
	 	!(@pdbFiles == @pdb_originalFiles xor $originalDirFlag)
	)
{
	print "Total: ".@pdbFiles." files in each raw data directory.\n";
	$check1Pass = 1;
}
else
{
	print "#ERROR: Unequal number of files in data directories.\n\n";
	print "hbplus files: ".@hbplusFiles."\n";
	print "clean files: ".@cleanFiles."\n";
	print "pdb files: ".@pdbFiles."\n";
	print "dssp files: ".@dsspFiles."\n";
	print "asa files: ".@asaFiles."\n";
	print "rsa files: ".@rsaFiles."\n";
	print "log files: ".@logFiles."\n";
	print "asac files: ".@asacFiles."\n";
	print "rsac files: ".@rsacFiles."\n";
	print "logc files: ".@logcFiles."\n";
	print "probe files: ".@probeFiles."\n";
	print "pdb_original files: ".@pdb_originalFiles."\n";
	print "\n#WARNING: Further analysis might be incomplete and/or erroneous. Recheck all files.\n";
	$check1Pass = 0;
}
if(! -e "$promotifResultsDir/BULGES"){print "#WARNING: 'BULGES' file is missing in PROMOTIF results directory.\n"; $check1Pass = 0;}
if($check1Pass){print "PASS\n";}
print "\n-------------\n\n";

#CHECK 2: CHECK FOR EMPTY FILES.
$check2Pass = 0;
print "CHECK 2: CHECK FOR EMPTY FILES.\n\n";
$emptyFlag = 0;
print "Empty files:\n";
foreach(@pdbFiles){	if(! -s $pdbDir."/".$_){ print $pdbDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@dsspFiles){	if(! -s $dsspDir."/".$_){ print $dsspDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@cleanFiles){	if(! -s $cleanDir."/".$_){ print $cleanDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@hbplusFiles){	if(! -s $hbplusDir."/".$_){ print $hbplusDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@asaFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@rsaFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@logFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@asacFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@rsacFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@logcFiles){	if(! -s $naccessDir."/".$_){ print $naccessDir."/".$_."\n"; $emptyFlag = 1;} }
foreach(@probeFiles){	if(! -s $probeDir."/".$_){ print $probeDir."/".$_."\n"; $emptyFlag = 1;} }

if($originalDirFlag == 1)
{
	foreach(@pdb_originalFiles){	if(! -s $pdb_originalDir."/".$_){ print $pdb_originalDir."/".$_."\n"; $emptyFlag = 1;} }
}
if($emptyFlag){print "#WARNING: Some files seem to be empty.\n"; $check2Pass = 0;}
else{$check2Pass = 1;}
if($check2Pass){print "PASS\n";}
print "\n-------------\n\n";

#CHECK 3: CHECK FOR PDB FORMAT FILES WITHOUT COORDINATE DATA.
$check3Pass = 0;
print "CHECK 3: CHECK FOR PDB FORMAT FILES WITHOUT COORDINATE DATA.\n\n";
$noCoordFlag = 0;
print "PDB format files without coordinate data:\n";
foreach(@pdbFiles){ if(! hasCoordData($pdbDir."/".$_)){print $pdbDir."/".$_."\n"; $noCoordFlag = 1;} }
foreach(@cleanFiles){ if(! hasCoordData($cleanDir."/".$_)){print $cleanDir."/".$_."\n"; $noCoordFlag = 1;} }
if($originalDirFlag == 1)
{
	foreach(@pdb_originalFiles){ if(! hasCoordData($pdb_originalDir."/".$_)){print $pdb_originalDir."/".$_."\n"; $noCoordFlag = 1;} }
}
if($noCoordFlag){print "#WARNING: Some files do not contain coordinate data.\n"; $check3Pass = 0;}
else{$check3Pass = 1;}
if($check3Pass){print "PASS\n";}
print "\n-------------\n\n";

#CHECK 4: CHECK NACCESS LOG FILES FOR POSSIBLE PRESENCE OF NON-STANDARD ATOMS.
$check4Pass = 0;
print "CHECK 4: CHECK NACCESS LOG FILES FOR POSSIBLE PRESENCE OF NON-STANDARD ATOMS.\n";
$naccessNonStandardList = `grep -l 'NON-STANDARD' $naccessDir/*.log*`;
if($naccessNonStandardList eq ''){$check4Pass = 1;}
else{print "WARNING: NON-STANDARD atoms found in following NACCESS log files. Guessed atomic radii may not be correct.\n$naccessNonStandardList\n";}
if($check4Pass){print "PASS\n";}
print "\n-------------\n\n";


sub hasCoordData
{
	open(PDB,$_[0])||print "Can not open PDB.\n";
	foreach my $line(<PDB>)
	{
		if($line=~m/^ATOM/ || $line=~m/^HETATM/){close(PDB); return(1);}
	}
	close(PDB);
	return(0);
}
