#!usr/bin/perl

$inDir = "../pdbClean";

opendir(INDIR,$inDir)||die"$!\n";

foreach $file(grep{/\.alt$/}readdir(INDIR))
{
	print "rm -f $inDir/$file\n";
	`rm -f $inDir/$file`;
}
