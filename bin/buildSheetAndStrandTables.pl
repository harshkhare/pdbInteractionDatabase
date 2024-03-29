#!usr/bin/perl

use strict;

###EXTRACTED FROM betaStrandAnalysis_7.pl
###SOME CHANGES ARE MADE TO WRITE ONLY THE STRAND INFORMATION EXCLUDING THE HBOND INFORMATION TO A FILE.
###THIS FILE COULD BE USED TO BE IMPORTED IN DATABASE AS A STRAND TABLE.

###DEFINITION OF USER INPUT VARIABLES START HERE.

my $dsspInDir = $ARGV[0]."/pdbDssp";
my $pdbInDir = $ARGV[0]."/pdb";
my $hbplusInDir = $ARGV[0]."/pdbHbplus";

my $tablesOutDir = $ARGV[1];

my $promotifBulgeFile = $ARGV[0]."/promotifResults/BULGES";

my $sheetInfoFile = "sheetInfoHashDump_2";

my $sheetTableFile = $tablesOutDir."/sheetTable";
my $sheetTableFile_nonredundant = $tablesOutDir."/sheetTable_nonredundant";

### $sheetInfoFileFormatted IS NOTHING BUT THE STRAND TABLE VIZ. strandTable_formatted
my $sheetInfoFileFormatted = $tablesOutDir."/strandTable_formatted";
my $sheetInfoFileFormatted_nonRedundantOutFile = $tablesOutDir."/strandTable_formatted_nonredundant";

my $resSheetStrandLinkTableFile = $tablesOutDir."/resSheetStrandLinkTable";

my %sheetInfoHash = ();
my @selectedSecStruct = ('B','E');

my %aaCode1to3 = ('A'=>'ALA','R'=>'ARG','N'=>'ASN','D'=>'ASP','C'=>'CYS','Q'=>'GLN','E'=>'GLU','G'=>'GLY','H'=>'HIS','I'=>'ILE','L'=>'LEU','K'=>'LYS','M'=>'MET','F'=>'PHE','P'=>'PRO','S'=>'SER','T'=>'THR','W'=>'TRP','Y'=>'TYR','V'=>'VAL');
my %aaCode3to1 = ('ALA'=>'A','ARG'=>'R','ASN'=>'N','ASP'=>'D','CYS'=>'C','GLN'=>'Q','GLU'=>'E','GLY'=>'G','HIS'=>'H','ILE'=>'I','LEU'=>'L','LYS'=>'K','MET'=>'M','PHE'=>'F','PRO'=>'P','SER'=>'S','THR'=>'T','TRP'=>'W','TYR'=>'Y','VAL'=>'V');

my %sheetInfoHashFormatted_nonRedundant = ();

my $fileCnt = 1;

#BUILD sheetInfoHash. THIS STEP CAN NOT BE OMITTED.
opendir(DSSPIN,$dsspInDir)||die"Can not open DSSPIN.\n";

my $cnt = 0;
foreach my $file(grep{/\.dssp$/}sort{$a cmp $b}readdir(DSSPIN))
{
	print "Processing file $file ...\n";
	print "Calling buildSheetInfoHash() ...\n";
	buildSheetInfoHash($dsspInDir,$file,buildDsspPdbResNumHash($dsspInDir,$file),buildStrandHash($dsspInDir,$file));

#	die;
#	$fileCnt++;
#	if($fileCnt > 1){goto SKIPFILES;}
	$cnt++;
	print "#$cnt\nDONE\n\n";

}
SKIPFILES:
close(DSSPIN);


#goto OMIT_INIT_FILE;

#OPTIONAL SECTION. FOR PRINTING INPUT FILES FOR FURTHER SUBROUTINES.
#CAN BE OMITTED IF FILES ALREADY PRESENT.
#PRINT $sheetInfoFile
print "Calling printSheetInfoHash() ...\n";
printSheetInfoHash($sheetInfoFile);
print "\tFile written: $sheetInfoFile\n\n";

#PRINT $sheetInfoFileFormatted
#THIS SUBROUTINE IS EDITED TO EXCLUDE H-BOND INFORMATION SO THAT IT CAN BE PRINTED LIKE STRAND TABLE.
print "Calling printFormatted() ...\n";
printFormatted($sheetInfoFileFormatted);
print "\tFile written: $sheetInfoFileFormatted\n\n";

#REMOVE CHAIN REDUNDANCY IN THE $sheetInfoFileFormatted
print "Calling removeChainRedundancy() ...\n";
removeChainRedundancy($sheetInfoFileFormatted,$sheetInfoFileFormatted_nonRedundantOutFile);
print "File written: $sheetInfoFileFormatted_nonRedundantOutFile\n\n";

#OPTIONAL SECTION ENDS HERE.





#PRINT %sheetInfoHashFormatted IN SHEET TABLE FORMAT
print "Calling printSheetTable() for complete sheet table...\n";
printSheetTable($sheetInfoFileFormatted,$sheetTableFile);
print "File written: $sheetTableFile\n\n";

#PRINT %sheetInfoHashFormatted_nonRedundant IN SHEET TABLE FORMAT
#print "Calling printSheetTable() for nonredundant sheet table...\n";
#printSheetTable($sheetInfoFileFormatted_nonRedundantOutFile,$sheetTableFile_nonredundant);
#print "File written: $sheetTableFile_nonredundant\n\n";


#PRINT TABLE THAT LINKS RESIDUE WITH SHEET AND STRAND ID.
print "Calling printResSheetStrandLinkTable() ...\n";
printResSheetStrandLinkTable($sheetInfoFileFormatted,$resSheetStrandLinkTableFile);
print "File written: $resSheetStrandLinkTableFile\n\n";



################################################

sub buildSheetInfoHash
{
	my($dsspInDir,$file,$dsspPdbResNumHash,$strandHash) = @_;

	my %strandHash = %{$strandHash};

	$file=~m/(.+)\.dssp$/;
#	$file=~m/(....)(.*?)_?(.?)\.dssp$/;

	my $pdbId = $1;

	open(DSSP,"$dsspInDir/$file")||die"Can not open DSSP. $dsspInDir/$file\n";

=head
  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
    1  114 A L              0   0   89      0, 0.0   128,-0.6     0, 0.0     2,-0.3   0.000 360.0 360.0 360.0 138.3   22.0   -3.3   -6.7
    2  115 A I        -     0   0  140      2,-0.1   126,-0.1   126,-0.1     0, 0.0  -0.620 360.0-109.2 -77.5 133.9   21.1   -5.9   -4.1
    3  116 A V  S    S+     0   0   41     -2,-0.3   121,-0.2   124,-0.1     2,-0.1  -0.882 104.6  53.1-107.2 138.7   17.4   -6.6   -3.6
    4  117 A P  S    S-     0   0  106      0, 0.0     2,-0.4     0, 0.0   120,-0.2   0.468  89.4-177.3 -68.4 136.0   15.7   -5.8   -1.3
    5  118 A Y  E     -A  123   0A  75    118,-2.8   118,-3.0    -2,-0.1     2,-0.5  -0.888  19.3-149.7-110.6 144.0   17.1   -2.4   -2.0
=cut

	my($dsspResNum,$pdbResNum,$chain,$aa,$bp1,$bp2,$sheetId,$secStruct,$strandId);

	my $dsspHeaderEndFlag = 0;
	my %dsspLines = ();

	foreach my $line(<DSSP>)
	{
		if($line=~m/  #/){$dsspHeaderEndFlag = 1;}
		if($dsspHeaderEndFlag)
		{
#  104  217 A H  E     +K   99   0B  96     -2,-0.5    -5,-0.3    -5,-0.3     3,-0.1  -0.431  39.8 171.9 -62.4 133.3    1.1    5.3  -18.5
#  105  218 A L  E     -     0   0   12     -7,-3.4     2,-0.3     1,-0.4    -6,-0.2   0.760  49.2 -25.6-109.4 -54.9   -0.1    2.4  -16.3
#  106  219 A L  E     -K   98   0B  16     -8,-1.6    -8,-3.6   -32,-0.0    -1,-0.4  -0.982  41.1-133.3-158.2 168.2   -1.9    3.9  -13.3

			if($line=~m/^(.{5}).{6}.....(.).{8}.{4}.{4}...{3}.*/)
			{

#This condition is modified because there are some residues which do not form backbone H-bonds with any residues,
#but are still involved in strand and have sec struct annotation 'E'. These are bulges within strands.
#For such residues there is no sheet id given in dssp files.
				
###$selectedSecStruct is changed to @selectedSecStruct to check both for sec struct B and E.
###B is isolated residue in beta bridge, while E is residue in strand. Both B and E have phi-psi corresponding to beta strand region in Ramachandran plot.
				#if($2 eq $selectedSecStruct)
				if(inArray($2,\@selectedSecStruct,0))
				{
					$dsspResNum = trim($1);

					$dsspLines{$dsspResNum} = $line;
				}
			}

		}
	}
	close(DSSP);


	foreach $strandId(sort{$a<=>$b}keys %strandHash)
	{
		foreach $dsspResNum(@{${$strandHash{$strandId}}[0]})
		{
#		print "$dsspResNum\n";
#=head
##Regex to parse dssp line is modified to consider the insertion code in the residue number
##			if($line=~m/^(.{5})(.{5}) (.) (.)  (.).{8}(.{4})(.{4})(.).(.{3}).*/)
			if($dsspLines{$dsspResNum}=~m/^(.{5})(.{6})(.).(.)..(.).{8}(.{4})(.{4})(.).(.{3}).*/)
			{
				($pdbResNum,$chain,$aa,$bp1,$bp2) = (trim($2),trim($3),trim($4),trim($6),trim($7));
	
				if($aa=~m/[a-z]/){$aa = 'C';}#else{$aa = $aa;}
	
				$sheetId = ${$strandHash{$strandId}}[2];
	
	##Edited to accomodate pdb res num for bp1 and bp2 at the end.
	##					${${${$sheetInfoHash{$pdbId}}{$sheetId}}{$strandCnt{$sheetId}+1}}{$dsspResNum} = [$aa,$pdbResNum,$chain,$bp1,$bp2];
	#					${${${$sheetInfoHash{$pdbId}}{$sheetId}}{$strandId}{$dsspResNum} = [$aa,$pdbResNum,$chain,$bp1,$bp2,${$dsspPdbResNumHash}{$chain}{$bp1},${$dsspPdbResNumHash}{$chain}{$bp2}];
						$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$dsspResNum} = [$aa,$pdbResNum,$chain,$bp1,$bp2,${$dsspPdbResNumHash}{$chain}{$bp1},${$dsspPdbResNumHash}{$chain}{$bp2}];
						#${${$sheetInfoHash{$pdbId}}{$sheetId}}{"analysis"} = 0;
			}
	
	#=cut
		}
	}
	
}


sub buildDsspPdbResNumHash
{
	my($dsspInDir,$file) = @_;

	open(DSSP,"$dsspInDir/$file")||print "#ERROR: Can not open DSSP. $dsspInDir/$file\n";

=head
  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
    1  114 A L              0   0   89      0, 0.0   128,-0.6     0, 0.0     2,-0.3   0.000 360.0 360.0 360.0 138.3   22.0   -3.3   -6.7
    2  115 A I        -     0   0  140      2,-0.1   126,-0.1   126,-0.1     0, 0.0  -0.620 360.0-109.2 -77.5 133.9   21.1   -5.9   -4.1
    3  116 A V  S    S+     0   0   41     -2,-0.3   121,-0.2   124,-0.1     2,-0.1  -0.882 104.6  53.1-107.2 138.7   17.4   -6.6   -3.6
    4  117 A P  S    S-     0   0  106      0, 0.0     2,-0.4     0, 0.0   120,-0.2   0.468  89.4-177.3 -68.4 136.0   15.7   -5.8   -1.3
    5  118 A Y  E     -A  123   0A  75    118,-2.8   118,-3.0    -2,-0.1     2,-0.5  -0.888  19.3-149.7-110.6 144.0   17.1   -2.4   -2.0
=cut

	my($dsspResNum,$pdbResNum,$chain,$aa,$bp1,$bp2,$sheetId);

	my $dsspHeaderEndFlag = 0;
	my %dsspPdbResNumHash = ();

	foreach my $line(<DSSP>)
	{
		if($dsspHeaderEndFlag)
		{
##Regex to parse dssp line is modified to consider the insertion code in the residue number
##			if($line=~m/^(.{5})(.{5}) (.) (.)  (.).{8}(.{4})(.{4})(.).(.{3}).*/)
			if($line=~m/^(.{5})(.{6})(.).*/)
			{
				($dsspResNum,$pdbResNum,$chain) = (trim($1),trim($2),trim($3));

				$dsspPdbResNumHash{$chain}{$dsspResNum} = $pdbResNum;
			}
		}
		if($line=~m/  #/){$dsspHeaderEndFlag = 1;}
	}

	close(DSSP);

#Add one more default entry for each chain such that dsspResNum=>pdbResNum is 0=>0.
#Note: Key of this hash is chain name.
	map{$dsspPdbResNumHash{$_}{0}=0;}keys %dsspPdbResNumHash;

#	map{print "$_=>$dsspPdbResNumHash{$_}{'pdbResNum'}\n";}sort{$a <=> $b}keys %dsspPdbResNumHash;

	return(\%dsspPdbResNumHash);
}

sub buildStrandHash
{
	my($dsspInDir,$file) = @_;

	my($dsspResNum,$pdbResNum,$secStruct,$sheetId,$strandCnt,$strandBeginFlag,$dsspHeaderEndFlag,$prevSheetId);

	my %strandHash = ();

	open(DSSP,"$dsspInDir/$file")||print "#ERROR: Can not open DSSP. $dsspInDir/$file\n";

	$strandBeginFlag = 0;
	$strandCnt = 1;
	foreach my $line(<DSSP>)
	{
		if($line=~m/  #/){$dsspHeaderEndFlag = 1;}
		if($dsspHeaderEndFlag)
		{
##Regex to parse dssp line is modified to consider the insertion code in the residue number
			if($line=~m/^(.{5})(.{6}).....(.).{8}.{4}.{4}(.)..{3}.*/)
			{

###$selectedSecStruct is changed to @selectedSecStruct, to check both for sec struct B and E.
###B is isolated residue in beta bridge, while E is residue in strand. Both B and E have phi-psi corresponding to beta strand region in Ramachandran plot.
				#if($3 eq $selectedSecStruct)
				if(inArray($3,\@selectedSecStruct,0))
				{
					if($4 ne ' ' && $prevSheetId ne $4 && $prevSheetId ne '' && $strandBeginFlag != 0){$strandCnt++;}
					
					($dsspResNum,$pdbResNum,$secStruct,$sheetId) = (trim($1),trim($2),trim($3),trim($4));
					push @{${$strandHash{$strandCnt}}[0]},$dsspResNum; 
					push @{${$strandHash{$strandCnt}}[1]},$sheetId;
#					print "$dsspResNum,$pdbResNum,$secStruct,$sheetId\n";
					$strandBeginFlag = 1;

					$prevSheetId = $sheetId;
				}
				else
				{
					if($strandBeginFlag)
					{
						$strandCnt++;
						$strandBeginFlag = 0;
					}
				}
			}
		}

	}

	map
	{

#Get unique sheetIds from array and append it to the array at $strandHash{$_}
		my %seen = (); my @uniqSheetIds = grep { ! $seen{$_} ++ } @{${$strandHash{$_}}[1]};
		$sheetId = pop(@{[sort @uniqSheetIds]});
		push @{$strandHash{$_}},$sheetId;

#Print msgs regarding bulges or errors in the strands.
		if(@uniqSheetIds == 2 && inArray('',\@uniqSheetIds,0)){print "\t> Bulge found in strand $_\n";}
		if(@uniqSheetIds == 2 && !inArray('',\@uniqSheetIds,0)){print "\t> *Error in sheet id in strand $_ : @{[sort @uniqSheetIds]}\n";}
		if(@uniqSheetIds > 2){print "\t> Error in sheet id in strand $_\n";}
	}sort{$a<=>$b}keys %strandHash;

#	print "$file: ";
#	map{print "$_ ";}sort{$a<=>$b}keys %strandHash;
#	print "\n";

	return(\%strandHash);
}


sub printSheetInfoHash
{
	my $sheetInfoFile = $_[0];

	open(SHEETINFO,">$sheetInfoFile")||print "#ERROR: Can not open SHEETINFO. $sheetInfoFile\n";
###PRINT %sheetInfoHash DATA STRUCTURE
	print SHEETINFO "PDB_ID\tSHEET_ID\tSTRAND_ID\tDSSP_RES_NUM\tRES_NAME\tPDB_RES_NUM\tCHAIN\tBP1\tBP2\tPDB_BP1\tPDB_BP2\n";
#	print SHEETINFO "#PDB_ID\tSHEET_ID\tSTRAND_ID\tEDGE_INFO\tNUM_EDGE_RES\tNUM_TOTAL_RES\tFRACTION_EDGE_RES\n";
	map
	{
		my $pdbId = $_;
###PDB ID IS TAKEN AS THE FILE NAME EXCEPT THE EXTENSION. BUT ACCORDING TO NEW CONVENTION INTRODUCED IN THIS VERSION OF PROGRAMS,
###THERE CAN BE EXTRA ANNOTATIONS IN THE FILE NAME. ONLY FIRST FOUR LETTERS SPECIFY THE PDB ID. OTHER CHARACTERS ARE ANNOTATIONS.
###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
###AS A CORRECTION, $pdbId_actual is set to $pdbId.
#		$pdbId=~m/(....)(.*?)_?(.?)/;
#		my $pdbId_actual = $1;
		my $pdbId_actual = $pdbId;
		#print "PDB ID: $pdbId_actual\n";

		map
		{
			my $sheetId = $_; 
			map
			{
				my $strandId = $_;
				map
				{
					if($_ eq 'e'){print SHEETINFO "#";}
					print SHEETINFO "$pdbId_actual\t$sheetId\t$strandId\t$_\t",join("\t",@{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}),"\n";
				}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}};
			}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$_}};
		}sort{$a cmp $b}keys %{$sheetInfoHash{$pdbId}};
		print SHEETINFO "\n";
	}sort{$a cmp $b}keys %sheetInfoHash;
###END PRINT
=head
	###PRINT %sheetInfoHash DATA STRUCTURE :: ALTERNATIVE WAY TO REPRESENT MULTIDIMENTIONAL HASH
	map
	{
		my $pdbId = $_;
###PDB ID IS TAKEN AS THE FILE NAME EXCEPT THE EXTENSION. BUT ACCORDING TO NEW CONVENTION INTRODUCED IN THIS VERSION OF PROGRAMS,
###THERE CAN BE EXTRA ANNOTATIONS IN THE FILE NAME. ONLY FIRST FOUR LETTERS SPECIFY THE PDB ID. OTHER CHARACTERS ARE ANNOTATIONS.
###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
###AS A CORRECTION, $pdbId_actual is set to $pdbId.
#		$pdbId=~m/(....)(.*?)_?(.?)/;
#		my $pdbId_actual = $1;
		my $pdbId_actual = $pdbId;

		map
		{
			my $sheetId = $_; 
			map
			{
				my $strandId = $_;
				map
				{
					print "$pdbId_actual\t$sheetId\t$strandId\t$_\t",join("\t",@{${${${$sheetInfoHash{$pdbId}}{$sheetId}}{$strandId}}{$_}}),"\n";
				}sort{$a <=> $b}keys %{${${$sheetInfoHash{$pdbId}}{$sheetId}}{$strandId}};
			}sort{$a <=> $b}keys %{${$sheetInfoHash{$pdbId}}{$_}};
		}sort{$a cmp $b}keys %{$sheetInfoHash{$pdbId}};
		print "\n";
	}sort{$a cmp $b}keys %sheetInfoHash;
	###END PRINT
=cut
}

sub printFormatted
{
	my $sheetInfoFile = $_[0];

	my($numEdgeRes,$numTotalRes,$fractionEdgeRes,$chain,$resNameNum,$resName,$bulgeResNameNum,$edgeResNameNum,$resSymbol);

	my %hbondHash = ();
	my %pdbDsspResNumHash = ();

###GET BULGE RESIDUES IN ALL PDB FILES FROM PROMOTIF OUTPUT.
	#my $promotifBulgeFile = "BULGES";
	my %promotifBulgeResList = getPromotifBulgeResList($promotifBulgeFile);

	open(SHEETINFO,">$sheetInfoFile")||print "#ERROR: Can not open SHEETINFO. $sheetInfoFile\n";
###PRINT %sheetInfoHash DATA STRUCTURE
#	print SHEETINFO "PDB_ID\tCHAIN\tSHEET_ID\tSTRAND_ID\tSTRAND_SEQ\tSTRAND_SEQ_AA\tNUM_TOTAL_RES\tEDGE_RES\tNUM_EDGE_RES\tFRACTION_EDGE\tBULGE_RES\tNUM_BULGE_RES\tFRACTION_BULGE\tNUM_BULGES\tBURRIED_RES\tNUM_BURRIED_RES\tFRACTION_BURRIED_RES\tSYMBOL_SEQ\tSEQ\tPARALLEL\tANTIPARALLEL\tNONSTRAND_HB\tNUM_HOH_HB\tNUM_SIDECHAIN_HB\tNUM_HETATM_HB\tNUM_OTHER_MAINCHN_HB\tNUM_TOTAL_NONSTRAND_HB\n";
	print SHEETINFO "PDB_ID\tCHAIN_ID\tSHEET_ID\tSTRAND_ID\tSTRAND_SEQ\tSTRAND_SEQ_AA\tNUM_TOTAL_RES\tEDGE_RES\tNUM_EDGE_RES\tFRACTION_EDGE\tBULGE_RES\tNUM_BULGE_RES\tFRACTION_BULGE\tNUM_BULGES\tBURRIED_RES\tNUM_BURRIED_RES\tFRACTION_BURRIED_RES\tSYMBOL_SEQ\tSEQ\tPARALLEL\tANTIPARALLEL\n";
#	print SHEETINFO "#PDB_ID\tSHEET_ID\tSTRAND_ID\tEDGE_INFO\tNUM_EDGE_RES\tNUM_TOTAL_RES\tFRACTION_EDGE_RES\n";
	map
	{
		my $pdbId = $_;
###PDB ID IS TAKEN AS THE FILE NAME EXCEPT THE EXTENSION. BUT ACCORDING TO NEW CONVENTION INTRODUCED IN THIS VERSION OF PROGRAMS,
###THERE CAN BE EXTRA ANNOTATIONS IN THE FILE NAME. ONLY FIRST FOUR LETTERS SPECIFY THE PDB ID. OTHER CHARACTERS ARE ANNOTATIONS.
###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
###AS A CORRECTION, $pdbId_actual is set to $pdbId.
#		$pdbId=~m/(....)(.*?)_?(.?)/;
#		my $pdbId_actual = $1;
		my $pdbId_actual = $pdbId;


		print "\tWriting formatted output for $pdbId.pdb ...\n";
		print "\tPDB ID: $pdbId_actual\n";
###BUILD HBOND HASH.
		%hbondHash = buildHbondHash($pdbId);
		%pdbDsspResNumHash = %{buildPdbDsspResNumHash($dsspInDir,$pdbId.".dssp")};
		map
		{
			my $sheetId = $_;

			map
			{
				my $strandId = $_;

				#print "$pdbId\t$
				my @strandSeq = ();
				my @strandSeqAa = ();
				my @bulgeRes = ();
				my @edgeRes = ();
				my @resSymbolSeq = ();
				my @burriedRes = ();
				my @nonStrandHb = ();
				my $waterHbCnt = 0;
				my $sideChainHbCnt = 0;
				my $otherHetAtmHbCnt = 0;
				my $otherMainChainHbCnt = 0;

				my @bp1Strand = ();
				my @bp2Strand = ();

				map
				{
					if($_ eq 'e')
					{
###This if condition was used when annotateEdgeStrands() was in use. An extra key 'e' was added to the hash.
###This key denoted the total number of edge residues(both edge and bulge residues) in a strand.
###Now this fuctionality is omitted as simple and separate counting of edge and bulge resides is done further in this function.

#						print SHEETINFO "#$pdbId\t",join("\t",@{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}),"\n";
#						($numEdgeRes,$numTotalRes,$fractionEdgeRes) = @{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}};
						print '';
					}
					else
					{
#						print SHEETINFO "$pdbId\t$sheetId\t$strandId\t$_\t",join("\t",@{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}),"\n";
						$chain = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[2];

#Check if both BP1 and BP2 are '0',
#if yes then put '^' after the residue number to denote that this residue does not make h-bonds with anyone.
#This means the residue is either flanking or a bulge in the strand.
						$resNameNum = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0].${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[1];
						$resName = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0];
						$bulgeResNameNum = "";
						$edgeResNameNum = "";
						$resSymbol = "N";

###[$aa,$pdbResNum,$chain,$bp1,$bp2,${$dsspPdbResNumHash}{$chain}{$bp1},${$dsspPdbResNumHash}{$chain}{$bp2}];
						my $pdbResNumTemp = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[1];
						my $chainTemp = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[2];
						if(exists($promotifBulgeResList{$pdbId}{$chainTemp}) && inArray($pdbResNumTemp,$promotifBulgeResList{$pdbId}{$chainTemp},0))
#						if(${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[3] eq '0' && ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[4] eq '0')
						{
#							push(@strandSeq, ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0].${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[1].'^');
#							push(@strandSeqAa, ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0].'^');
#							push(@bulgeRes,${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0].${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[1].'^');
							$resNameNum .= '^';
							$resName .= '^';
							$bulgeResNameNum = $resNameNum;
							$resSymbol = "B";
						}
						else
						{
							if(${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[3] eq '0' || ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[4] eq '0')
							{
								$resNameNum .= '*';
								$resName .= '*';
								$edgeResNameNum = $resNameNum;
								$resSymbol = "E";
							}
							else
							{
								push(@burriedRes, $resName);
							}
						}

						push(@strandSeq, $resNameNum);
						push(@strandSeqAa, $resName);
						push(@resSymbolSeq, $resSymbol);
						if($bulgeResNameNum ne ""){push(@bulgeRes, $bulgeResNameNum);}
						if($edgeResNameNum ne ""){push(@edgeRes, $edgeResNameNum);}

						#print "$pdbId $sheetId $strandId $_ => @{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}\n";


###FIND HOW THE HBOND POTENTIAL IS SATISFIED, WITH ANOTHTER STRAND OR WITH ANY OTHER ATOM.
###HBOND ANALYSIS FOR EDGE/BULGE RESIDUES.
						my $ch = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[2];
						my $resNum = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[1];
						my $resName = ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[0];

						###FILL @bp1Strand
						if(${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[3] ne '0'){push @bp1Strand,${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[3];}

						###FILL @bp2Strand
						if(${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[4] ne '0'){push @bp2Strand,${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[4];}


=head
						if(${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[3] eq '0' ||
							 ${$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}[4] eq '0')
						{
							###CHECK IF N OR O OF THIS RESIDUE HBOND WITH ANY OTHER ATOM. USE HBPLUS OUTPUT TO FIND THIS.
							my @strandHbInfo = getNonStrandHbondInfo(\%hbondHash,\%pdbDsspResNumHash,$pdbId,$ch,$sheetId,$resNum,$resName,$resSymbol);
							push @nonStrandHb,@{$strandHbInfo[0]};
							$waterHbCnt += $strandHbInfo[1];
							$sideChainHbCnt += $strandHbInfo[2];
							$otherHetAtmHbCnt += $strandHbInfo[3];

#							print "*$_ => @{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}\n";
							#print "^$pdbId  ".$ch."_".$resNum."_".$resName."_O_M"."\n";
#							if($resSymbol eq 'E' || $resSymbol eq 'B'){
#							}
						}
=cut
###END HBOND ANALYSIS FOR EDGE/BULGE RESIDUES.

					}
				}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}};
				#print "$pdbId>>".@nonStrandHb."\n";

#FIND THE STRANDS THAT ARE HBONDED TO THIS STRAND ALONG WITH THE PARALLEL OR ANTIPARALLEL ANNOTATION.
#getStrandIdOf SUBROUTINE WILL RETURN THE STRAND ID WHEN PDBID, SHEET_ID AND DSSP_RES_NUM IS PROVIDED.
#				print "Strand $strandId Finished.\n@bp1Strand\n@bp2Strand\n";
				my $bp1StrandId = getStrandIdOf($pdbId,$sheetId,$bp1Strand[0]);
				my $bp2StrandId = getStrandIdOf($pdbId,$sheetId,$bp2Strand[0]);

				my @parallelStrands = ();
				my @antiparallelStrands = ();
				if($bp1StrandId ne '')
				{
					if($bp1Strand[0]-$bp1Strand[$#bp1Strand] < 0){push @parallelStrands,$bp1StrandId;}
					else{push @antiparallelStrands,$bp1StrandId;}
				}
				if($bp2StrandId ne '')
				{
					if($bp2Strand[0]-$bp2Strand[$#bp2Strand] < 0){push @parallelStrands,$bp2StrandId;}
					else{push @antiparallelStrands,$bp2StrandId;}
				}


#FIND NUMBER OF BULGES. THESE ARE THE CONTINUOUS PATCHES OF 'B's IN THE SYMBOL SEQ.
				my @patches = split(/[EN]+/,join("",@resSymbolSeq));
				if($patches[0] eq ''){shift @patches;}
				if($patches[$#patches] eq ''){pop @patches;}

#CREATE PURE SEQ (WITHOUT ANY SYMBOL LIKE '*' OR '^'.)
				my @pureSeq = @strandSeqAa;
				map{~s/(.+)[\^\*]$/$1/}@pureSeq;

				#@nonStrandHb = getUniqueFromArray(@nonStrandHb);

#				print SHEETINFO "$pdbId\t$chain\t$sheetId\t$strandId\t",join(",",@strandSeq),"\t",join(",",@strandSeqAa),"\t",($#strandSeqAa+1),"\t",join(",",@edgeRes),"\t",($#edgeRes+1),"\t",sprintf("%4.3f",($#edgeRes+1)/($#strandSeqAa+1)),"\t",join(",",@bulgeRes),"\t",($#bulgeRes+1),"\t",sprintf("%4.3f",($#bulgeRes+1)/($#strandSeqAa+1)),"\t",($#patches+1),"\t",join(",",@burriedRes),"\t",($#burriedRes+1),"\t",sprintf("%4.3f",($#burriedRes+1)/($#strandSeqAa+1)),"\t",join("",@resSymbolSeq),"\t",join("",@pureSeq),"\t",join(",",@parallelStrands),"\t",join(",",@antiparallelStrands),"\t",join(',',@nonStrandHb),"\t",$waterHbCnt,"\t",$sideChainHbCnt,"\t",$otherHetAtmHbCnt,"\t",$otherMainChainHbCnt,,"\t",($#nonStrandHb+1),"\n";
				print SHEETINFO "$pdbId_actual\t$chain\t$sheetId\t$strandId\t",join(",",@strandSeq),"\t",join(",",@strandSeqAa),"\t",($#strandSeqAa+1),"\t",join(",",@edgeRes),"\t",($#edgeRes+1),"\t",sprintf("%4.3f",($#edgeRes+1)/($#strandSeqAa+1)),"\t",join(",",@bulgeRes),"\t",($#bulgeRes+1),"\t",sprintf("%4.3f",($#bulgeRes+1)/($#strandSeqAa+1)),"\t",($#patches+1),"\t",join(",",@burriedRes),"\t",($#burriedRes+1),"\t",sprintf("%4.3f",($#burriedRes+1)/($#strandSeqAa+1)),"\t",join("",@resSymbolSeq),"\t",join("",@pureSeq),"\t",join(",",@parallelStrands),"\t",join(",",@antiparallelStrands),"\n";

			}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$_}};
		}sort{$a cmp $b}keys %{$sheetInfoHash{$pdbId}};
#		print SHEETINFO "\n";
	}sort{$a cmp $b}keys %sheetInfoHash;
###END PRINT

	close(SHEETINFO);

}

sub removeChainRedundancy
{
	my($sheetInfoFileFormatted,$sheetInfoFileFormatted_nonRedundantOutFile) = @_;

	my($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ);
	my($PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB);


	my %strandInfo = ();

	my $firstLine = "";
	open(IN,$sheetInfoFileFormatted)||print "#ERROR: Can not open IN.\n";

	open(OUT,'>'.$sheetInfoFileFormatted_nonRedundantOutFile)||print "Can not open OUT.\n";

	foreach my $line(<IN>)
	{
		chomp($line);

		%strandInfo = ();
		if($line=~m/^PDB_ID/)
		{
#			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB) = @{[split(/\t/,$line)]};
			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL) = @{[split(/\t/,$line)]};
			$firstLine = $line;
		}
		else
		{
#			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL},$strandInfo{$NONSTRAND_HB},$strandInfo{$NUM_HOH_HB},$strandInfo{$NUM_SIDECHAIN_HB},$strandInfo{$NUM_HETATM_HB},$strandInfo{$NUM_OTHER_MAINCHN_HB},$strandInfo{$NUM_TOTAL_NONSTRAND_HB}) = @{[split(/\t/,$line)]};
			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL}) = @{[split(/\t/,$line)]};
=head
#Columns in the formatted output file:

BULGE_RES
BURRIED_RES
CHAIN
EDGE_RES
FRACTION_BULGE
FRACTION_BURRIED_RES
FRACTION_EDGE
NUM_BULGES
NUM_BULGE_RES
NUM_BURRIED_RES
NUM_EDGE_RES
NUM_TOTAL_RES
PDB_ID
SEQ
SHEET_ID
STRAND_ID
STRAND_SEQ
STRAND_SEQ_AA
SYMBOL_SEQ

=cut

###CREATE FILTERED HASH TO REMOVE REDUNDANCY DUE TO SAME CHAINS.
			$sheetInfoHashFormatted_nonRedundant{$strandInfo{$PDB_ID}.'_'.$strandInfo{$STRAND_SEQ}} = $line;
		}
	}

###PRINT OUTPUT FILE WHERE THE REDUNDANCY DUE TO SAME CHAINS IS REMOVED.
	print OUT "$firstLine\n";
	map{print OUT "$sheetInfoHashFormatted_nonRedundant{$_}\n";}sort{$a cmp $b} keys %sheetInfoHashFormatted_nonRedundant;
	close(OUT);

}


sub printResSheetStrandLinkTable
{
	my($sheetInfoFileFormatted,$resSheetStrandLinkTableFile) = @_;

	my($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ);
	my($PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB);


	my %strandInfo = ();
	my %sheetTableHash = ();

	my @resSheetStrandLinkLines = ();

	my $firstLine = "";
	open(IN,$sheetInfoFileFormatted)||print "#ERROR: Can not open IN.\n";

	open(OUT,'>'.$resSheetStrandLinkTableFile)||print "Can not open OUT.\n";

	foreach my $line(<IN>)
	{
		chomp($line);

		%strandInfo = ();
		if($line=~m/^PDB_ID/)
		{
#			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB) = @{[split(/\t/,$line)]};
			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL) = @{[split(/\t/,$line)]};
			$firstLine = $line;
		}
		else
		{
#			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL},$strandInfo{$NONSTRAND_HB},$strandInfo{$NUM_HOH_HB},$strandInfo{$NUM_SIDECHAIN_HB},$strandInfo{$NUM_HETATM_HB},$strandInfo{$NUM_OTHER_MAINCHN_HB},$strandInfo{$NUM_TOTAL_NONSTRAND_HB}) = @{[split(/\t/,$line)]};
			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL}) = @{[split(/\t/,$line)]};

###CREATE FILTERED HASH TO REMOVE REDUNDANCY DUE TO SAME CHAINS.
#			$sheetInfoHashFormatted_nonRedundant{$strandInfo{$PDB_ID}.'_'.$strandInfo{$STRAND_SEQ}} = $line;
			push @{$sheetTableHash{$strandInfo{$PDB_ID}."\t".$strandInfo{$CHAIN}."\t".$strandInfo{$SHEET_ID}}}, $strandInfo{$STRAND_ID};

			map
			{
				$_=~s/.(.+)/$1/;
				push @resSheetStrandLinkLines,"$strandInfo{$PDB_ID}"."\t".$strandInfo{$CHAIN}."\t".$_."\t".$strandInfo{$SHEET_ID}."\t".$strandInfo{$STRAND_ID}."\n";
			}split(/\**\^*,\**\^*|\^*\**$/,$strandInfo{$STRAND_SEQ});

		}
	}

###PRINT OUTPUT FILE.
	print OUT "PDB_ID\tCHAIN_ID\tRES_NUM\tSHEET_ID\tSTRAND_ID\n";
	print OUT @resSheetStrandLinkLines;
	close(OUT);

}

sub printSheetTable
{
	my($sheetInfoFileFormatted,$sheetTableFile) = @_;

	my($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ);
	my($PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB);


	my %strandInfo = ();
	my %sheetTableHash = ();

	my $firstLine = "";
	open(IN,$sheetInfoFileFormatted)||print "#ERROR: Can not open IN.\n";

	open(OUT,'>'.$sheetTableFile)||print "Can not open OUT.\n";

	foreach my $line(<IN>)
	{
		chomp($line);

		%strandInfo = ();
		if($line=~m/^PDB_ID/)
		{
#			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL,$NONSTRAND_HB,$NUM_HOH_HB,$NUM_SIDECHAIN_HB,$NUM_HETATM_HB,$NUM_OTHER_MAINCHN_HB,$NUM_TOTAL_NONSTRAND_HB) = @{[split(/\t/,$line)]};
			($PDB_ID,$CHAIN,$SHEET_ID,$STRAND_ID,$STRAND_SEQ,$STRAND_SEQ_AA,$NUM_TOTAL_RES,$EDGE_RES,$NUM_EDGE_RES,$FRACTION_EDGE,$BULGE_RES,$NUM_BULGE_RES,$FRACTION_BULGE,$NUM_BULGES,$BURRIED_RES,$NUM_BURRIED_RES,$FRACTION_BURRIED_RES,$SYMBOL_SEQ,$SEQ,$PARALLEL,$ANTIPARALLEL) = @{[split(/\t/,$line)]};
			$firstLine = $line;
		}
		else
		{
#			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL},$strandInfo{$NONSTRAND_HB},$strandInfo{$NUM_HOH_HB},$strandInfo{$NUM_SIDECHAIN_HB},$strandInfo{$NUM_HETATM_HB},$strandInfo{$NUM_OTHER_MAINCHN_HB},$strandInfo{$NUM_TOTAL_NONSTRAND_HB}) = @{[split(/\t/,$line)]};
			($strandInfo{$PDB_ID},$strandInfo{$CHAIN},$strandInfo{$SHEET_ID},$strandInfo{$STRAND_ID},$strandInfo{$STRAND_SEQ},$strandInfo{$STRAND_SEQ_AA},$strandInfo{$NUM_TOTAL_RES},$strandInfo{$EDGE_RES},$strandInfo{$NUM_EDGE_RES},$strandInfo{$FRACTION_EDGE},$strandInfo{$BULGE_RES},$strandInfo{$NUM_BULGE_RES},$strandInfo{$FRACTION_BULGE},$strandInfo{$NUM_BULGES},$strandInfo{$BURRIED_RES},$strandInfo{$NUM_BURRIED_RES},$strandInfo{$FRACTION_BURRIED_RES},$strandInfo{$SYMBOL_SEQ},$strandInfo{$SEQ},$strandInfo{$PARALLEL},$strandInfo{$ANTIPARALLEL}) = @{[split(/\t/,$line)]};

###CREATE FILTERED HASH TO REMOVE REDUNDANCY DUE TO SAME CHAINS.
#			$sheetInfoHashFormatted_nonRedundant{$strandInfo{$PDB_ID}.'_'.$strandInfo{$STRAND_SEQ}} = $line;
			push @{$sheetTableHash{$strandInfo{$PDB_ID}."\t".$strandInfo{$CHAIN}."\t".$strandInfo{$SHEET_ID}}}, $strandInfo{$STRAND_ID};
		}
	}

###PRINT OUTPUT FILE.
	print OUT "PDB_ID\tCHAIN_ID\tSHEET_ID\tSTRANDS\tNUM_STRANDS\n";
	map{print OUT "$_\t",join(',',@{$sheetTableHash{$_}})."\t".@{$sheetTableHash{$_}}."\n";}sort{$a cmp $b} keys %sheetTableHash;
	close(OUT);

}


sub getPromotifBulgeResList
{
	my $promotifBulgeFile = $_[0];

	my %promotifBulgeResList = ();

	open(BULGE,$promotifBulgeFile) || print "Can not open BULGE.\n";

#1A1S P C A 106  A  -117.3  138.6 A 127  N  -100.3  105.2 A 128  G   -81.7  -13.8           -999.9 -999.9           -999.9 -999.9 
#1AFA A S 1 168  F   -83.2  126.4 1 161  D  -127.3   33.9 1 162  E   -67.1  -37.8 1 163  V   -64.5  -50.4           -999.9 -999.9 
#1AFA A G 1 204  V   -98.6  155.8 1 207  G    90.4  -14.0 1 208  L   -75.5  157.5           -999.9 -999.9           -999.9 -999.9 
#1D7P A S M2241  T  -110.2   -2.2 M2297  L  -109.1  114.4 M2298  D  -126.1  107.5 M2299  P   -77.2  168.3 M2300  P   -72.3  172.7
#1D7P A C M2312  S  -145.6  153.0 M2258  K   -88.1  -38.2 M2259  E  -139.3  148.7           -999.9 -999.9           -999.9 -999.9 

	foreach (<BULGE>)
	{
#=============1D7P= =A= =S= =M==2241 = =T=  =-110.2= =  -2.2= =M==2297 = =L=  =-109.1= = 114.4= =M==2298 = =D=  =-126.1= = 107.5= =M==2299 = =P=  = -77.2= = 168.3= =M==2300 = =P=  = -72.3= = 172.7=        
#=============1AFA= =A= =S= =1== 168 = =F=  = -83.2= = 126.4= =1== 161 = =D=  =-127.3= =  33.9= =1== 162 = =E=  = -67.1= = -37.8= =1== 163 = =V=  = -64.5= = -50.4= = ==     = = =  =-999.9= =-999.9=        
		if($_=~m/(....).(.).(.).(.)(.....).(.)..(......).(......).(.)(.....).(.)..(......).(......).(.)(.....).(.)..(......).(......).(.)(.....).(.)..(......).(......).(.)(.....).(.)..(......).(......)/)
		{

			my($pdbId,$prlAntiPrlFlag,$blgType,
			 $chX,$resNumX,$resNameX,$phiX,$psiX,
			 $ch1,$resNum1,$resName1,$phi1,$psi1,
			 $ch2,$resNum2,$resName2,$phi2,$psi2,
			 $ch3,$resNum3,$resName3,$phi3,$psi3,
			 $ch4,$resNum4,$resName4,$phi4,$psi4)
			=
			(trim($1),trim($2),trim($3),
			 trim($4),trim($5),trim($6),trim($7),trim($8),
			 trim($9),trim($10),trim($11),trim($12),trim($13),
			 trim($14),trim($15),trim($16),trim($17),trim($18),
			 trim($19),trim($20),trim($21),trim($22),trim($23),
			 trim($24),trim($25),trim($26),trim($27),trim($28));

###IF BULGE IS BENT BULGE THEN THERE ARE ONLY TWO RESIDUES 1 AND 2. RESIDUE X IS ABSENT.
###HENCE DO THE FOLLOWING:
###(RESIDUE 2 PARAMETERS) = (RESIDUE 1 PARAMETERS)
###(RESIDUE 1 PARAMETERS) = (RESIDUE X PARAMETERS)
###(RESIDUE X PARAMETERS) = (NULL VALUES)
			if($phi2 eq '-999.9' && $phi3 eq '-999.9' && $phi4 eq '-999.9')
			{
				($ch2,$resNum2,$resName2,$phi2,$psi2) = ($ch1,$resNum1,$resName1,$phi1,$psi1);
				($ch1,$resNum1,$resName1,$phi1,$psi1) = ($chX,$resNumX,$resNameX,$phiX,$psiX);
				($chX,$resNumX,$resNameX,$phiX,$psiX) = ('','','','','');
			}

			push @{$promotifBulgeResList{$pdbId}{$ch1}} , ($resNum1,$resNum2,$resNum3,$resNum4);

###COUNT AMINO ACIDS WHICH ARE NOT NULL. THESE ARE COUNTS OF AMINO ACIDS FOUND IN BULGES.
#			map{ if($_ ne '' && inArray($_,[keys %aaBlgCnt],0)){ $aaBlgCnt{$_}++; $aaTotalBlgCnt++;} }($resName1,$resName2,$resName3,$resName4);

=head	
			print "$pdbId,$prlAntiPrlFlag,$blgType,\n
			 $chX,$resNumX,$resNameX,$phiX,$psiX,\n
			 $ch1,$resNum1,$resName1,$phi1,$psi1,\n
			 $ch2,$resNum2,$resName2,$phi2,$psi2,\n
			 $ch3,$resNum3,$resName3,$phi3,$psi3,\n
			 $ch4,$resNum4,$resName4,$phi4,$psi4\n-------------------------------\n";
=cut
		}
	}

	close(BULGE);

	return(%promotifBulgeResList);

}


sub buildHbondHash
{
	my $pdbId = $_[0];

	my($chD,$resNumD,$resNameD,$atomD,$chA,$resNumA,$resNameA,$atomA,$daDist,$dCat,$aCat);

	my $headerEndFlag = 0;
	my %hbondHash = ();

	open(HBPLUS,$hbplusInDir."/".$pdbId.".hb2")||print "#ERROR: Can not open HBPLUS: $pdbId.hb2\n";

	foreach my $line(<HBPLUS>)
	{
		if($headerEndFlag)
		{
#							 =A==0003-==HIS== ND1= =A==0029-==ASP== OD2== 2.90= =S==S= = 26= = 5.92= =137.9= = 2.08= =110.7= =122.4= =    2=
			$line=~m/(.)(.....)(...)(....).(.)(.....)(...)(....)(.....).(.)(.).(...).(.....).(.....).(.....).(.....).(.....).(.....).*/;

			($chD,$resNumD,$resNameD,$atomD) = ($1,$2,$3,trim($4));
			($chA,$resNumA,$resNameA,$atomA) = ($5,$6,$7,trim($8));
			if(inArray($resNameD,[keys %aaCode3to1],0)){$resNameD = $aaCode3to1{$resNameD};}
			if(inArray($resNameA,[keys %aaCode3to1],0)){$resNameA = $aaCode3to1{$resNameA};}

			($daDist) = (trim($9));
			($dCat,$aCat) = ($10,$11);

			##'-' at the end and '0's at the start are removed if present.
			##Note: Res num can be negative. Hence the '-?' is used before '\d+'.
			$resNumD=~s/^0*(-?\d+[A-Z]?)-?$/$1/;
			$resNumA=~s/^0*(-?\d+[A-Z]?)-?$/$1/;

			push @{$hbondHash{$chD."_".$resNumD."_".$resNameD."_".$atomD."_".$dCat}}, [$chA."_".$resNumA."_".$resNameA."_".$atomA."_".$aCat, $daDist];
			push @{$hbondHash{$chA."_".$resNumA."_".$resNameA."_".$atomA."_".$aCat}}, [$chD."_".$resNumD."_".$resNameD."_".$atomD."_".$dCat, $daDist];
		}
		if($line=~m/type/){$headerEndFlag = 1;}

	}
	close(HBPLUS);
#	print "@{$hbondHash{'A_1087_HOH_O_H'}}\n";
#	print "@{${$hbondHash{'A_128_P_O_M'}}[0]}\n";

#	print keys %hbondHash;
=head	
	map
	{
		my $key = $_;
		map
		{
			print "$key => @{$_}\n";
		}@{$hbondHash{$key}};
	}keys %hbondHash;
=cut

	return(%hbondHash);
}


sub buildPdbDsspResNumHash
{
	my($dsspInDir,$file) = @_;

	open(DSSP,"$dsspInDir/$file")||print "#ERROR: Can not open DSSP. $dsspInDir/$file\n";

=head
  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
    1  114 A L              0   0   89      0, 0.0   128,-0.6     0, 0.0     2,-0.3   0.000 360.0 360.0 360.0 138.3   22.0   -3.3   -6.7
    2  115 A I        -     0   0  140      2,-0.1   126,-0.1   126,-0.1     0, 0.0  -0.620 360.0-109.2 -77.5 133.9   21.1   -5.9   -4.1
    3  116 A V  S    S+     0   0   41     -2,-0.3   121,-0.2   124,-0.1     2,-0.1  -0.882 104.6  53.1-107.2 138.7   17.4   -6.6   -3.6
    4  117 A P  S    S-     0   0  106      0, 0.0     2,-0.4     0, 0.0   120,-0.2   0.468  89.4-177.3 -68.4 136.0   15.7   -5.8   -1.3
    5  118 A Y  E     -A  123   0A  75    118,-2.8   118,-3.0    -2,-0.1     2,-0.5  -0.888  19.3-149.7-110.6 144.0   17.1   -2.4   -2.0
=cut

	my($dsspResNum,$pdbResNum,$chain,$aa,$bp1,$bp2,$sheetId);

	my $dsspHeaderEndFlag = 0;
	my %pdbDsspResNumHash = ();

	foreach my $line(<DSSP>)
	{
		if($dsspHeaderEndFlag)
		{
##Regex to parse dssp line is modified to consider the insertion code in the residue number
##			if($line=~m/^(.{5})(.{5}) (.) (.)  (.).{8}(.{4})(.{4})(.).(.{3}).*/)
			if($line=~m/^(.{5})(.{6})(.).*/)
			{
				($dsspResNum,$pdbResNum,$chain) = (trim($1),trim($2),trim($3));

				$pdbDsspResNumHash{$chain}{$pdbResNum} = $dsspResNum;
			}
		}
		if($line=~m/  #/){$dsspHeaderEndFlag = 1;}
	}

	close(DSSP);

#Add one more default entry for each chain such that pdbResNum=>dsspResNum is 0=>0.
#Note: Key of this hash is chain name.
	map{$pdbDsspResNumHash{$_}{0}=0;}keys %pdbDsspResNumHash;

#	map{print "$_=>$pdbDsspResNumHash{$_}{'dsspResNum'}\n";}sort{$a <=> $b}keys %pdbDsspResNumHash;

	return(\%pdbDsspResNumHash);
}

sub getNonStrandHbondInfo
{
	my %hbondHash = %{$_[0]};
	my %pdbDsspResNumHash = %{$_[1]};
	my($pdbId,$ch,$sheetId,$resNum,$resName,$resSymbol) = ($_[2],$_[3],$_[4],$_[5],$_[6],$_[7]);

###	@nonStrandHb => LIST OF ALL HBONDS THAT ARE NOT INVOLVED IN FORMING THE BETA SHEET.
###	$waterHbCnt = COUNT OF HBONDS ONLY WIHT OXYGEN OF WATER MOLECULE.
###	$sideChainHbCnt = COUNT OF HBONDS ONLY WITH SIDE-CHAIN ATOMS OF ANY RESIDUE. THESE RESIDUES CAN BE THOSE FROM SAME SHEET/STRAND.
###	$otherHetAtmHbCnt = COUNT OF HBONDS ONLY WITH HETEROATOMS OTHER THAN WATER.
###	$otherMainChainHbCnt = COUNT OF HBONDS ONLY WITH MAIN-CHAIN N OR O OF RESIUDES NOT INVOLVED IN SAME SHEET.


#	print "Checking $resNum  $ch\n";

	my @nonStrandHb = ();
	my $waterHbCnt = 0;
	my $sideChainHbCnt = 0;
	my $otherHetAtmHbCnt = 0;
	my $otherMainChainHbCnt = 0;

	if(exists $hbondHash{$ch."_".$resNum."_".$resName."_N_M"})
	{
		map
		{#A_128_P_N_M
			if(${$_}[0]=~m/(.)_(.+)_(.+)_(.+)_([A-Z])/)
			{
				if($5 ne 'M' || getSheetIdOf($pdbId,$pdbDsspResNumHash{$1}{$2}) ne $sheetId)
				{
					if(!inArray($resName."_".$resNum.$ch."_N-".$3."_".$2.$1."_"."$4",\@nonStrandHb,0))
					{
						push @nonStrandHb, $resName."_".$resNum.$ch."_N-".$3."_".$2.$1."_"."$4";
						if($3 eq "HOH"){$waterHbCnt++;}
						if($5 eq 'S'){$sideChainHbCnt++;}
						if($5 eq 'H' && $3 ne "HOH"){$otherHetAtmHbCnt++;}
						if($5 eq 'M'){$otherMainChainHbCnt++;}
					}
				}
			}
		}@{$hbondHash{$ch."_".$resNum."_".$resName."_N_M"}};
	}
	if(exists $hbondHash{$ch."_".$resNum."_".$resName."_O_M"})
	{
		map
		{#A_128_P_O_M
			if(${$_}[0]=~m/(.)_(.+)_(.+)_(.+)_([A-Z])/)
			{
				if($5 ne 'M' || getSheetIdOf($pdbId,$pdbDsspResNumHash{$1}{$2}) ne $sheetId)
				{
					if(!inArray($resName."_".$resNum.$ch."_O-".$3."_".$2.$1."_"."$4",\@nonStrandHb,0))
					{
						push @nonStrandHb, $resName."_".$resNum.$ch."_O-".$3."_".$2.$1."_"."$4";
						if($3 eq "HOH"){$waterHbCnt++;}
						if($5 eq 'S'){$sideChainHbCnt++;}
						if($5 eq 'H' && $3 ne "HOH"){$otherHetAtmHbCnt++;}
						if($5 eq 'M'){$otherMainChainHbCnt++;}
					}
				}
			}
		}@{$hbondHash{$ch."_".$resNum."_".$resName."_O_M"}};
	}

	#print "$pdbId,$ch,$sheetId,$resNum,$resName: $waterHbCnt,$sideChainHbCnt,$otherHetAtmHbCnt,$otherMainChainHbCnt,  ".@nonStrandHb."\n@nonStrandHb\n\n";
	return(\@nonStrandHb,$waterHbCnt,$sideChainHbCnt,$otherHetAtmHbCnt,$otherMainChainHbCnt);

}

sub getSheetIdOf
{
	my($pdbId,$dsspResNum) = @_;

#	print "Finding Sheet Id for @_\n";
#=head
	map
	{
		my $sheetId = $_;
		map
		{
			my $strandId = $_;
			map
			{
				if($dsspResNum eq $_)
				{
					return($sheetId);
#					print ">>$_ => $sheetId | @{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}\n";

				}
			}sort {$a <=> $b} keys %{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}};
		}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$sheetId}};
	}keys %{$sheetInfoHash{$pdbId}};
#=cut
#	print "\n\n";
#die;
	return(0);
}

sub getStrandIdOf
{
	my($pdbId,$sheetId,$dsspResNum) = @_;

#	print "Finding Strand Id for @_\n";

	map
	{
		my $strandId = $_;
		map
		{
			if($dsspResNum eq $_)
			{
#				print "$dsspResNum == $_ :: Strand Id = $strandId\n";
				return($strandId);
			}
#			print "*$_ = @{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}{$_}}\n";
		}sort{$a <=> $b}keys %{$sheetInfoHash{$pdbId}{$sheetId}{$strandId}};
	}keys %{$sheetInfoHash{$pdbId}{$sheetId}};
#	print "\n\n";
	return('');
}



###########################################


sub trim
{
	my $str = $_[0];
	$str=~s/^\s*(.*)/$1/;
	$str=~s/\s*$//;
	return $str;
}

sub inArray
{
###CHECKS PRESENCE OF $e IN THE @arr
###SYNTAX :: inArray($e,\@arr,$mode)
###$mode = 1 :: NUMERICAL COMPARISON
###$mode = 0 :: NON-NUMERICAL COMPARISON
###RETURN VALUE :: 1 : $e PRESENT IN $arr
###RETURN VALUE :: 0 : $e NOT PRESENT IN $arr

	my $e = $_[0];
	my @arr = @{$_[1]};
	my $mode = $_[2];

	if($mode)
	{
		foreach(@arr)	{	if($e == $_){return 1;}	}
	}
	else
	{
		foreach(@arr)	{	if($e eq $_){return 1;}	}
	}
	return 0;
}

