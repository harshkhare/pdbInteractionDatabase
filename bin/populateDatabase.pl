#!usr/bin/perl

use DBI();

my $sqlFile = $ARGV[0];
my $database_name = $ARGV[1];
my $mysql_host = $ARGV[2];
my $mysql_uname = $ARGV[3];
my $mysql_passwd = $ARGV[4];
my $databaseWriteLogFile = $ARGV[5];

#print "$recreateTablesFile, $sqlFile, $database_name, $mysql_host, $mysql_uname, $mysql_passwd\n";



open(SQLLOG,">>".$databaseWriteLogFile)||die "DIED: Can not open SQLLOG in append mode: $databaseWriteLogFile\n";


#print "SQL: mysql -u$mysql_uname -p$mysql_passwd $database_name<$sqlFile\n";
#print `mysql -u$mysql_uname -p$mysql_passwd $database_name<$sqlFile`;

#=head
print "Processing file $sqlFile ...\n";
open(SQL,$sqlFile)||die "DIED: Can not open SQL: $sqlFile\n";

###CONNECT TO DATABASE
my $dbh = DBI->connect("DBI:mysql:database=$database_name;host=$mysql_host","$mysql_uname", "$mysql_passwd",{'RaiseError' => 1, 'AutoCommit' => 0});
$lineCnt = 1;
foreach $qry (<SQL>)
{
	chomp $qry;
	if(trim($qry) ne "")
	{
		#print "SQL: $qry\n";
		eval
		{
			$dbh->do($qry);
		};
		if($@){print "File: $sqlFile :: DBI ERROR on line $lineCnt\n\n"; exit(-1);}
	}
	$lineCnt++;
}

$dbh->commit;
$dbh->disconnect;

close(SQL);
#=cut

print SQLLOG "SQLFILE\t$sqlFile\tDONE\n";

close(SQLLOG);

sub trim
{
	my $str = $_[0];
	$str=~s/^\s*(.*)/$1/;
	$str=~s/\s*$//;
	return $str;
}


