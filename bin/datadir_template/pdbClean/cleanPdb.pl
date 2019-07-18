#!usr/bin/perl

$pdbInDir = "../pdb";

opendir(PDBINDIR,$pdbInDir)||die"Can not open PDBINDIR.\n";

foreach $file(grep{/\.pdb$/}readdir(PDBINDIR))
{

	print `echo \$PID_MOLPROBITY_PATH`."/reduce -Trim $pdbInDir/$file\n";
	$reduceOut = `\$PID_MOLPROBITY_PATH/reduce -Trim $pdbInDir/$file`;
	print "\n";

	open(TEMP,">$file")||die "Can not open TEMP for writing.\n";
	print TEMP $reduceOut;
	close(TEMP);

	print `echo \$PID_CLEAN_PATH`."/clean_harsh $file\n";
	$out = `\$PID_CLEAN_PATH clean_harsh $file`;
	print "$out\n";

	$file=~m/(.+)\.pdb$/;

	print "mv ".$1.".new $file\n";
	`mv $1.new $file`;
	print "\n";

	if(-e "$1.alt")
	{
		print "rm -f $1.alt\n";
		`rm -f $1.alt`;
	}

}

