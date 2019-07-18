#!usr/bin/perl


$pdbInDir = "../pdb";

opendir(PDBINDIR,$pdbInDir)||die"Can not open PDBINDIR.\n";

foreach $file(grep{/\.pdb$/}readdir(PDBINDIR))
{
	print `echo \$PID_DSSP_PATH`."/dssp-2.0.4-linux-i386 $pdbInDir/$file\n";
	$dsspOut = `\$PID_DSSP_PATH/dssp-2.0.4-linux-i386 $pdbInDir/$file`;

	$file=~m/(.+)\.pdb$/;

	open(DSSP,">$1.dssp")||die "Can not open DSSP for writing.\n";
	print DSSP $dsspOut;
	close(DSSP);

}

