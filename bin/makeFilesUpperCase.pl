$inDir = "../data/input/harsh_top8000/pdbNaccess";
$extension = "rsac";

opendir(IN,$inDir)||die"$!\n";

my $cnt = 0;

foreach $file(grep{/\.$extension$/}readdir(IN))
{
#	print "$file\n";
	$file=~m/(.+)(\..+)/;

	$ucName = uc($1);
	$ext = $2;
	print "mv $inDir/$file $inDir/$ucName$ext\n";
	`mv $inDir/$file $inDir/$ucName$ext`;
	$cnt++;
}

closedir(IN);

print "Total Files: $cnt\n";
