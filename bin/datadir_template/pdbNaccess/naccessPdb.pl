#!urs/bin/perl

$pdbInDir = "../pdb";

opendir(PDBINDIR,$pdbInDir)||die"Can not open PDBINDIR.\n";

foreach $file(grep{/\.pdb$/}readdir(PDBINDIR))
{

#REMOVE HYDROGENS
	print `echo \$PID_MOLPROBITY_PATH`."/reduce -Trim $pdbInDir/$file\n";
	$reduceOut = `\$PID_MOLPROBITY_PATH/reduce -Trim $pdbInDir/$file`;
	#print "\n";

	open(TEMP,">$file")||die "Can not open TEMP for writing.\n";
	print TEMP $reduceOut;
	close(TEMP);

###RUN NACCESS WITH OPTION -c
	print `echo \$PID_NACCESS_PATH`."/naccess $file -c\n";
	$out = `\$PID_NACCESS_PATH/naccess $file -c`;
	print "$out";

	$file=~m/(.+)\.pdb$/;

	print "mv $1.asa $1.asac\n";
	`mv $1.asa $1.asac`;
	print "mv $1.rsa $1.rsac\n";
	`mv $1.rsa $1.rsac`;
	print "mv $1.log $1.logc\n";
	`mv $1.log $1.logc`;

###RUN NACCESS WITHOUT OPTION -c
	print `echo \$PID_NACCESS_PATH`."/naccess $file\n";
	$out = `\$PID_NACCESS_PATH/naccess $file`;
	print "$out";

	$file=~m/(.+)\.pdb$/;


	print "rm $file\n";
	`rm $file`;
	print "\n";

}

