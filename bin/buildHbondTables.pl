#!usr/bin/perl

use strict;

my $hbplusInDir = $ARGV[0]."/pdbHbplus";
my $hbondTableFile = "hbondTable";

my $tablesOutDir = $ARGV[1];

my %aaCode1to3 = ('A'=>'ALA','R'=>'ARG','N'=>'ASN','D'=>'ASP','C'=>'CYS','Q'=>'GLN','E'=>'GLU','G'=>'GLY','H'=>'HIS','I'=>'ILE','L'=>'LEU','K'=>'LYS','M'=>'MET','F'=>'PHE','P'=>'PRO','S'=>'SER','T'=>'THR','W'=>'TRP','Y'=>'TYR','V'=>'VAL');
my %aaCode3to1 = ('ALA'=>'A','ARG'=>'R','ASN'=>'N','ASP'=>'D','CYS'=>'C','GLN'=>'Q','GLU'=>'E','GLY'=>'G','HIS'=>'H','ILE'=>'I','LEU'=>'L','LYS'=>'K','MET'=>'M','PHE'=>'F','PRO'=>'P','SER'=>'S','THR'=>'T','TRP'=>'W','TYR'=>'Y','VAL'=>'V');

my %hbondHash = ();

my $fileCnt = 1;

#BUILD sheetInfoHash. THIS STEP CAN NOT BE OMITTED.
opendir(HBPLUSDIR,$hbplusInDir)||die"Can not open HBPLUSDIR.\n";

open(HBONDTABLE,">".$tablesOutDir."/".$hbondTableFile)||die "Can not open HBONDTABLE.\n";

print HBONDTABLE "PDB_ID\tHBOND_NUM\t";
print HBONDTABLE "DONOR_CHAIN_ID\tDONOR_RESNUM\tDONOR_RESNAME\tDONOR_ATNAME\t";
print HBONDTABLE "ACCEPTOR_CHAIN_ID\tACCEPTOR_RESNUM\tACCEPTOR_RESNAME\tACCEPTOR_ATNAME\t";
print HBONDTABLE "DONOR_CAT\tACCEPTOR_CAT\t";
print HBONDTABLE "D_A_DIST\tAAS\tCA_CA_DIST\tD_H_A_ANGLE\tH_A_DIST\tH_A_AA_ANGLE\tD_A_AA_ANGLE\n";

#foreach my $pdbId(grep{s/(.+?)(_.)?\.hb2$/$1/}sort{$a cmp $b}readdir(HBPLUSDIR))
my $cnt = 0;
foreach my $hb2File(grep{/.*\.hb2$/}sort{$a cmp $b}readdir(HBPLUSDIR))
{
	print "Processing file $hb2File ...\n";
	###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
	###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
	#$hb2File =~ m/(....)(.*?)_?(.?)\.hb2$/;
	$hb2File =~ m/(.+)\.hb2$/;
	my $pdbId = $1;
	print "PDB ID: $1\n";
	print "\tCalling buildHbondHash() ...\n";

	%hbondHash = buildHbondHash($hb2File);

	print "\tAppending rows to $hbondTableFile ...\n";

	map
	{
		my $hbondNum = $_;
		print HBONDTABLE "$pdbId\t$hbondNum\t";###THIS IS CANDIDATE KEY
		print HBONDTABLE "$hbondHash{$_}{'DONOR_CHAIN'}\t$hbondHash{$_}{'DONOR_RESNUM'}\t$hbondHash{$_}{'DONOR_RESNAME'}\t$hbondHash{$_}{'DONOR_ATNAME'}\t";
		print HBONDTABLE "$hbondHash{$_}{'ACCEPTOR_CHAIN'}\t$hbondHash{$_}{'ACCEPTOR_RESNUM'}\t$hbondHash{$_}{'ACCEPTOR_RESNAME'}\t$hbondHash{$_}{'ACCEPTOR_ATNAME'}\t";
		print HBONDTABLE "$hbondHash{$_}{'DOANR_CAT'}\t$hbondHash{$_}{'ACCEPTOR_CAT'}\t";
		print HBONDTABLE "$hbondHash{$_}{'D-A_DIST'}\t$hbondHash{$_}{'AAS'}\t$hbondHash{$_}{'CA-CA_DIST'}\t$hbondHash{$_}{'D-H-A_ANGLE'}\t$hbondHash{$_}{'H-A_DIST'}\t$hbondHash{$_}{'H-A-AA_ANGLE'}\t$hbondHash{$_}{'D-A-AA_ANGLE'}\n";
	
	}sort {$a <=> $b} keys %hbondHash;

	$cnt++;
	print "#$cnt\nDONE\n\n";


#	die;
#	$fileCnt++;
#	if($fileCnt > 2){goto SKIPFILES;}

}
#SKIPFILES:
close(HBPLUSDIR);
close(HBONDTABLE);

###############################################################


sub buildHbondHash
{
	my $hb2File = $_[0];

	my($chD,$resNumD,$resNameD,$atomD,$chA,$resNumA,$resNameA,$atomA,$daDist,$catD,$catA);
	my($aas,$caCaDist,$dhaAngle,$haDist,$haAaAngle,$daAaAngle,$hbondNum);

	my $headerEndFlag = 0;
	my %hbondHash = ();

	open(HBPLUS,$hbplusInDir."/".$hb2File)||print "#ERROR: Can not open HBPLUS: $hb2File\n";

	foreach my $line(<HBPLUS>)
	{
		if($headerEndFlag)
		{
#							 =A==0003-==HIS== ND1= =A==0029-==ASP== OD2== 2.90= =S==S= = 26= = 5.92= =137.9= = 2.08= =110.7= =122.4= =    2=
			$line=~m/(.)(.....)(...)(....).(.)(.....)(...)(....)(.....).(.)(.).(...).(.....).(.....).(.....).(.....).(.....).(.....).*/;

			($chD,$resNumD,$resNameD,$atomD) = ($1,$2,$3,trim($4));
			($chA,$resNumA,$resNameA,$atomA) = ($5,$6,$7,trim($8));
			if(inArray($resNameD,[keys %aaCode3to1],0)){$resNameD = $resNameD;}
			if(inArray($resNameA,[keys %aaCode3to1],0)){$resNameA = $resNameA;}

			($daDist) = (trim($9));
			($catD,$catA) = ($10,$11);

			($aas,$caCaDist,$dhaAngle,$haDist,$haAaAngle,$daAaAngle,$hbondNum) = (trim($12),trim($13),trim($14),trim($15),trim($16),trim($17),trim($18));

			##'-' at the end and '0's at the start are removed if present.
			##Note: Res num can be negative. Hence the '-?' is used before '\d+'.
			$resNumD=~s/^(-?)0*(-?\d+[A-Z]?)-?$/$1$2/;
			$resNumA=~s/^(-?)0*(-?\d+[A-Z]?)-?$/$1$2/;

			$hbondHash{$hbondNum} = 
			{
				"DONOR_CHAIN"=>$chD,"DONOR_RESNUM"=>$resNumD,"DONOR_RESNAME"=>$resNameD,"DONOR_ATNAME"=>$atomD,"DOANR_CAT"=>$catD,
				"ACCEPTOR_CHAIN"=>$chA,"ACCEPTOR_RESNUM"=>$resNumA,"ACCEPTOR_RESNAME"=>$resNameA,"ACCEPTOR_ATNAME"=>$atomA,"ACCEPTOR_CAT"=>$catA,
				"D-A_DIST"=>$daDist,"AAS"=>$aas,"CA-CA_DIST"=>$caCaDist,"D-H-A_ANGLE"=>$dhaAngle,
				"H-A_DIST"=>$haDist,"H-A-AA_ANGLE"=>$haAaAngle,"D-A-AA_ANGLE"=>$daAaAngle
			};
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

