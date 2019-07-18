#!usr/bin/perl

$pdbInDir = "../pdbClean";

opendir(PDBINDIR,$pdbInDir)||die"Can not open PDBINDIR.\n";

foreach $file(grep{/\.pdb$/}readdir(PDBINDIR))
{
	`grep \'\\(^ATOM  \\|^HETATM\\)..........\\(\\s\\|A\\)' $pdbInDir/$file>$file`;
	print `echo \$PID_HBPLUS_PATH`."/hbplus $file\n";
	$out = `\$PID_HBPLUS_PATH/hbplus $file`;
	print "$out\n";
	`rm $file`;
}
