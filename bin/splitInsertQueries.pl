#!usr/bin/perl

$pdbDir = $ARGV[0];
$insertQueriesFile = $ARGV[1];
$qryDir = $ARGV[2];

$numProc = 3;

#print "$insertQueriesFile\n$qryDir\n";


print "ls $pdbDir | grep \'\\.pdb\$\'\n\n";
@pdbList = split("\n",`ls $pdbDir | grep \'\\.pdb\$\'`);
$pdbListLen = $#pdbList + 1;
$chunkSize = int($pdbListLen/$numProc);

#print ">> $chunkSize $chunkSize ".($pdbListLen - ($numProc - 1)*$chunkSize)."\n";

@chunks = ();
foreach (1..$numProc)
{
	if($_ != $numProc){push @chunks,[splice(@pdbList,0,$chunkSize)];}
	else              {push @chunks,[splice(@pdbList,0)];}
}


#=head
###FORKING FIRST $numProc PROCESSES.

my @childs = ();

for(my $i=0;$i<$numProc;$i++)
{
	my $pid = fork();
	if($pid)
	{
		#parent
		print "PARENT($i) :: PID $pid\n";
		push(@childs,$pid);
	}
	elsif($pid == 0)
	{
		#child
		foreach (0..$numProc-1)
		{
			if($i == $_)
			{
				print "CHILD $i\n";

				splitSqlFile($chunks[$i]);

				print "CHILD $i :: DONE\n";
				print "CHILD $i :: EXITING\n";
				exit(0);
			}
		}
#
	}
	else
	{
		die "Could not fork.\n";
	}

}

foreach(@childs)
{
	waitpid($_,0);
}

#=cut

print "DONE SPLITTING QUERIES.\n\n";

##############################################

sub splitSqlFile
{
	my @pdbList = @{$_[0]};

	foreach $pdbId (@pdbList)
	{
		$pdbId=~s/(.+)\.pdb$/$1/;
		print "Writing sql file for $pdbId ...\n";
		open(OUT,">$qryDir/$pdbId.sql")||print "Can not open OUT for writing.\n";
		#print "grep '$pdbId' $insertQueriesFile\n";
		print OUT `grep '$pdbId' $insertQueriesFile`;
		close(OUT);
	}
}

