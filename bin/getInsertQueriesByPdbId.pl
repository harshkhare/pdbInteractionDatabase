#!usr/bin/perl

$tableDir = $ARGV[0];

$qryDir = $ARGV[1];

mkdir($qryDir);

open(CHAINTABLE,"$tableDir/chainTable")||die "Can not open CHAINTABLE.\n";
$cnt = 0;
%pdbIds = ();
foreach $line(<CHAINTABLE>)
{
	if($cnt != 0)
	{
		@line = split("\t",$line);
		$pdbIds{$line[0]}++;
	}
	$cnt++;
}


$cnt = 0;
foreach $pdbId (sort{$a cmp $b}keys %pdbIds)
{
	print "Writing insert queries for $pdbId ...\n";
	$qry = `perl createInsertQueries_forOnePdb.pl $tableDir $pdbId`;
	open(QRY,">".$qryDir."/".$pdbId.".sql") || die "Can not open QRY.\n";
	print QRY $qry."\n";
	close(QRY);

	$cnt++;
	print "#$cnt\nDONE\n\n";
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

