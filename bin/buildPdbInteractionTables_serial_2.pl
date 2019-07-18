#!usr/bin/perl

use DBI;

####################################################################################################
#                                                                                                  #
#    WRITTEN BY: HARSHAVARDHAN KHARE,                                                              #
#                DEPARTMENT OF PHYSICS,                                                            #
#                INDIAN INSTITUTE OF SCIENCE,                                                      #
#                BANGALORE - 560012                                                                #
#                                                                                                  #
#==================================================================================================#
#                                                                                                  #
#    THIS SCRIPT CALLS OTHER PROGRAMS THAT BUILD DIFFERENT TABLES.                                 #
#    RUNS SERIALLY USING SINGLE CPU.                                                               #
#                                                                                                  #
#==================================================================================================#
#                                                                                                  #
#    STEPS:                                                                                        #
#                                                                                                  #
# 1. FETCH PDB FILES. IF THERE ARE SEPARATE PDB FILES FOR EACH CHAIN OF SAME PROTEIN,              # 
#    THEN PROGRAM mergeChains.pl CAN BE USED TO MERGE THEM INTO A SINGLE PDB FILE.                 #
#    [NOTE: THE top8000 DATA SET HAS ONLY REPRESENTATIVE CHAINS OF PDB FILES,                      #
#    THUS MERGING THEM MAY NOT GIVE THE FULL PROTEIN. THIS HAS TO BE KEPT IN MIND WHEN             #
#    CONSIDERING INTERACTIONS BETWEEN DIFFERENT CHAINS.]                                           #
#                                                                                                  #
# 2. THE FINAL DATA SET CONTAINS PDB FILES WITH NAMES IN FOLLOWING FORMAT:                         #
#    (....)(.*?)_?(.?)\.pdb                                                                        #
#    WHERE,                                                                                        #
#    $1 = PDB ID                                                                                   #
#    $2 = ANNOTATION / INFORMATION ABOUT THE PDB FILE                                              #
#    $3 = CHAIN NAME (SINGLE LETTER)                                                               #
#                                                                                                  #
# 3. CREATE A DIRECTORY TO HOLD ALL THE RAW DATA OF THE SELECTED DATA SET.                         #
#    TYPICALLY IT IS SITUATED IN rawData DIRECTORY. FOR EXAMPLE: rawData/dataDir                   #
#                                                                                                  #
# 4. CREATE FOLLOWING SUB-DIRECTORIES IN rawData/dataDir                                           #
#    rawData/dataDir/pdb                                                                           #
#    rawData/dataDir/pdbDssp                                                                       #
#    rawData/dataDir/pdbClean                                                                      #
#    rawData/dataDir/pdbHbplus                                                                     #
#    rawData/dataDir/promotifResults                                                               #
#    rawData/dataDir/pdbOriginal (*OPTIONAL)                                                       #
#                                                                                                  #
#    [*NOTE: PDB FILES IN DIRECTORY pdb MAY BE THE PROCESSED FILES BY SOME PROGRAM, FOR EXAMPLE,   #
#    PROGRAM reduce TO ADD MISSING HYDROGENS.                                                      #
#    THUS ANOTHER DIRECTORY IS GIVEN TO HOLD THE PDB FILES THAT ARE NOT PROCESSED USING            #
#    ANY PROGRAM VIZ. pdbOriginal.                                                                 #
#    THIS IS AN OPTIONAL DIRECTORY. IF CREATED, THEN IT SHOULD CONTAIN SAME NUMBER OF PDB FILES    #
#    AS IN THE DIRECTORY pdb.]                                                                     #
#                                                                                                  #
# 5. COPY THE PDB FILES TO rawData/dataDir/pdb (AND OPTIONNALLY TO rawData/dataDir/pdbOriginal).   #
#                                                                                                  #
# 6. NOW WE HAVE TO KEEP SOME PROGRAMS IN THE ABOVE MENTIONED SUB-DIRECTORIES.                     #
#     _______________________________________                                                      #
#    |  DIRECTORY        |  PROGRAM         |                                                      #
#    |-------------------|------------------|                                                      #
#    |  pdbDssp          |  runDssp.pl      |                                                      #
#    |  pdbClean         |  cleanPdb.pl     |                                                      #
#    |  pdbHbplus        |  hbplusPdb.pl    |                                                      #
#    |  promotifResults  |  runPromotif.pl  |                                                      #
#    |___________________|__________________|                                                      #
#                                                                                                  #
#    [NOTE: FIRST CHECK THAT PROMOTIF IS RUNNING. PROMOTIF NEEDS csh TO RUN.]                      #
#                                                                                                  #
# 7. OUTPUT DIRECTORY TO STORE TABLES AND SQL INSERT QUERIES IS pdbInteractionTables.              #
#                                                                                                  #
# 8. NOW WE ARE READY TO START RUNNING THE PROGRAMS. THIS HAS BEEN AUTOMATED BY THIS SCRIPT.       #
#    [NOTE: DO NOT FORGET TO CHECK IF THE OUTOUT DIRECTORY FOR TABLES IS ALREADY EXISTS.           #
#    THE SCRIPT WILL ANYWAY CHECK IF COMMANDLINE ARGUMENT --overwrite IS GIVEN.]                   #
#                                                                                                  #
#    FOLLOWING IS THE SEQUENCE OF TASKS OF THE SCRIPT IN BRIEF.                                    #
#                                                                                                  #
#    1) PARSE COMMAND LINE ARGUMENTS                                                               #
#    2) CHECK IF DATA DIRECTORY IS PRESENT                                                         #
#    3) CHECK IF OUTPUT DIRECTORY IS ALREADY PRESENT                                               #
#    4) DISPLAY ALL ARGUMENTS AND THEIR VALUES GIVEN BY THE USER                                   #
#    5) RUN DSSP, CLEAN, HBPLUS AND PROMOTIF ON THE FILES IN DATA DIRECTORY TO GENERATE RAW DATA   #
#    6) PROGRAM: generateRawData.sh                                                                #
#                GOES TO RESPECTIVE DIRECTORIES IN DATA DIRECTORY AND                              #
#                RUNS runDssp.pl, cleanPdb.pl, hbplusPdb.pl, runPromotif.pl.                       #
#    7) PROGRAM: checkRawData.pl                                                                   #
#                CHECK INTEGRITY OF RAW DATA FILES IN DATA DIRECTORY. DIES IF ERROR OR WARNING     #
#                FOUND.                                                                            #
#    8) MAKE OUTPUT DIRECTORY                                                                      #
#    9) PROGRAM: buildPiInteractionTables.py                                                       #
#                CALCULATES XH-PI, PI-PI AND CH-O INTERACTIONS.                                    #
#                WRITES xhTable, xhpiTable, ringTable, pipiTable, choTable.                        #
#   10) PROGRAM: buildHbondTables.pl                                                               #
#                WRITES hbondTable USING HBPLUS OUTPUT.                                            #
#   11) PROGRAM: buildSheetAndStrandTables.pl                                                      #
#                WRITES sheetTable, strandTable_formatted, strandTable_formatted_nonredundant,     #
#                resStrandSheetLinkTable.                                                          #
#   12) PROGRAM: buildPdbTables.py                                                                 #
#                WRITES chainTable, residueTable, atomTable.                                       #
#   13) PROGRAM: createInsertQueries.pl                                                            #
#                WRITES insertQueries_<datadir>.sql WHICH CAN BE IMPORTED IN MYSQL DATABASE.       #
#                                                                                                  #
####################################################################################################


###DEFINE GLOBAL VARIABLES
###SET DEFAULT VALUES.
my $dataDirTemplateDefault = "datadir_template";
my $databaseWriteLogDefault = "database_write_log.log";
my $recreateTablesDefault = "recreateTables.sql";
my $createTablesDefault = "createTables.sql";

###PARSE COMMAND LINE ARGUMENTS.
###IF --file IS GIVEN THEN ARGUMENTS IN THE FILE SPECIFIED BY --file WILL BE GIVEN PREFERENCE OVER THE COMMAND LINE ARGUMENTS.
@argArr = split(/-+/,join(" ",@ARGV));
shift @argArr;
#print join("*",@argArr)."\n";

my %args = ();
foreach (@argArr)
{
	my @arg = split(/\s/,$_);
	my $arg = shift @arg;
	my $value = join(" ",@arg);
	#print "$arg : $value\n";
	$args{$arg} = $value;
}

###PRINT HELP AND EXIT IF --help IS GIVEN. THIS WILL WORK ONLY IF GIVEN ON COMMAND LINE.
###--help IN THE FILE SPECIFIED BY --file WILL NOT HAVE ANY EFFECT.
if(exists $args{'help'})
{
	print "
 Usage: $0 [options]\n
 options:
 --datadir                    Full or relative path to directory
                              containing raw data.
 --outputdir                  Full or relative path to output 
                              directory.
 --overwrite                  No value required. Its presence
                              specifies to overwrite the output
                              directory and its contents.
 --add_hydrogens              No value required. Adds missing
                              hydrogens to the pdb files in 
                              pdb/ directory.
 --update_hydrogens           No value required. Removes previous
                              hydrogens (if any) and adds new
                              hydrogens to the pdb files in pdb/
                              directory. Works only if
                              --add_hydrogens is specified.
 --skip_generate_rawdata      No value required. Skips running
                              programs to generate raw data from
                              pdb files.
 --skip_build_tables          No value required. Skips runnig
                              programs to build pdb interaction
                              tables in ASCII format.
 --skip_build_insert_queries  No value required. Skips runnig
                              program to build sql insert queries.
 --skip_populate_database     No value required. Skips runnig
                              program to populate the database
                              using sql insert queries.
 --datadir_template           Uses this directory as a template to
                              generate raw data directory specified
                              by --datadir.
                              Default: datadir_template/
 --file                       Path to the file containing arguments
                              separated by new line. These will be
                              given preference over the command
                              line arguments.
 --recreate_tables_file       SQL file containing queries to delete
                              and recreate database tables.
                              Default: recreateTables.sql
 --create_tables_file         SQL file containing queries to delete
                              and recreate database tables.
                              Default: createTables.sql
 --database_name              Name of the database. Required.
 --write_database             Takes two values: 'overwrite',
                              'append'. Required.
 --database_write_log         Specifies database write log file.
                              Default: database_write_log.log
                              Required.
 --mysql_host                 MySQL host name. Required.
 --mysql_uname                MySQL user name. Required.
 --mysql_passwd               MySQL pass word. Required.
 --help                       Print this help text and exit.
                              Ignores all other arguments.
                              This will work only if specified on
                              command line.
                              It will have no effect if given in
                              the file specified by --file.
\n";
exit(1);
}

###PARSE ARGUMENTS FROM OPTIONS FILE. SKIP LINES STARTING WITH #.
if(defined $args{'file'})
{
	print "#WARNING: Arguments in --file will be given preference.\n";
	if(! -e $args{'file'}){print "#WARNING: Can not open the file specified by --file : $args{'file'}\n";}
	else
	{
		open(FILE,$args{'file'})||print "Can not open FILE.\n";
		foreach (<FILE>)
		{
			chomp;
			if($_!~/^#/)
			{
				$_=~s/-+(.+)/$1/;
				my @arg = split(/\s/,$_);
				my $arg = shift @arg;
				my $value = join(" ",@arg);
				#print "--file => $arg : $value\n";
				$args{$arg} = $value;
			}
		}
		close(FILE);
	}
}
###REMOVE BLANK KEY FROM %args
map{if($_ eq ''){delete $args{$_};}}keys %args;

###CHECK FOR NON-EXISTENT BUT CRITICALLY IMPORTANT ARGUMENTS THAT HAVE TO BE SPECIFIED BY USER.
if(!exists $args{'database_write_log'}){die "DIED: Please specify the database_write_log option to make the program to search for the log file.\n";}
if(exists $args{'write_database'})
{
	if($args{'write_database'} eq 'overwrite' && !exists $args{'recreate_tables_file'}){ die "DIED: Please specify the recreate_tables_file option.\n";}
	if($args{'write_database'} eq 'append'    && !exists $args{'create_tables_file'})  { die "DIED: Please specify the create_tables_file option.\n";}
}

###ASSIGN DEFAULT VALUES FOR BLANK VALUES OF ARGUMETNS.
if(trim($args{'datadir_template'}) eq "")    {$args{'datadir_template'} = $dataDirTemplateDefault;}
if(trim($args{'database_write_log'}) eq "")  {$args{'database_write_log'} = $databaseWriteLogDefault;}
if(trim($args{'recreate_tables_file'}) eq ""){$args{'recreate_tables_file'} = $recreateTablesDefault;}
if(trim($args{'create_tables_file'}) eq "")  {$args{'create_tables_file'} = $createTablesDefault;}


###START SCRIPT
print "\n### START SCRIPT: $0 ###\n\n";


if(!$args{'datadir'}){die "DIED: #ERROR: --datadir not specified. Try --help option to get help.\n";}
if(!$args{'outputdir'}){die "DIED: #ERROR: --outputdir not specified. Try --help option to get help.\n";}

my $dataDir = $args{'datadir'};
my $outputDir = $args{'outputdir'};

#my $dataDir = "rawData/top8000_subset2";
#my $outputDir = "pdbInteractionTables/top8000_subset2";


#goto HBOND;
#goto PDBTABLES;

###CHECK IF DATA DIRECTORY IS PRESENT.
if(! -d $dataDir){die "DIED: #ERROR: Data directory specified by --datadir not found.\n";}
elsif(!exists $args{'datadir_template'})
{
	if(! -d "$dataDir/pdbDssp"){die "DIED: #ERROR: Directory $dataDir/pdbDssp not found. You may use --datadir_template option.\n";}
	if(! -d "$dataDir/pdbClean"){die "DIED: #ERROR: Directory $dataDir/pdbClean not found. You may use --datadir_template option.\n";}
	if(! -d "$dataDir/pdbHbplus"){die "DIED: #ERROR: Directory $dataDir/pdbHbplus not found. You may use --datadir_template option.\n";}
	if(! -d "$dataDir/pdbNaccess"){die "DIED: #ERROR: Directory $dataDir/pdbNaccess not found. You may use --datadir_template option.\n";}
	if(! -d "$dataDir/promotifResults"){die "DIED: #ERROR: Directory $dataDir/promotifResults not found. You may use --datadir_template option.\n";}
}
else
{
	print "Generating raw data directories from template ...\n";
	print "CMD: cp -r $args{'datadir_template'}/* $dataDir\n";	
	`cp -r $args{'datadir_template'}/* $dataDir`;
	print "\n=================================================\n";
}


###CHECK IF OUTPUT DIRECTORY IS ALREADY PRESENT.
if(-d $outputDir && !exists $args{'overwrite'}){die "DIED: Directory $outputDir already exists. Please use --overwrite option.\n";}

###DISPLAY ALL ARGUMENTS AND THEIR VALUES GIVEN BY THE USER.
print "\n=================================================\n";
print "Arguments:\n";
map{print "$_ : $args{$_}\n";}sort{$a cmp $b}keys %args;
print "=================================================\n\n";


#die "DIED: OK\n";

###RUN DSSP, CLEAN, HBPLUS, NACCESS, PROBE AND PROMOTIF ON THE FILES IN DATA DIRECTORY TO GENERATE RAW DATA
if(!exists $args{'skip_generate_rawdata'})
{
	print "Program: generateRawData.sh ...\n";

###REMOVE(OPTIONAL) AND ADD HYDROGNES
	if(exists $args{'add_hydrogens'})
	{
		if(exists $args{'update_hydrogens'})
		{
			my $generateRawData_cmdout = system("sh generateRawData.sh $dataDir update_hydrogens");
		}
		else
		{
			my $generateRawData_cmdout = system("sh generateRawData.sh $dataDir only_add_hydrogens");
		}
	}
	else
	{
		print "Skipped: add hydrogens.\n";
		my $generateRawData_cmdout = system("sh generateRawData.sh $dataDir");
	}
	print "=================================================\n\n";

	print "$generateRawData_cmdout\n";
}
else
{
	print "Skipped: generate raw data.\n";
}
print "=================================================\n\n";

#die "DIED: RAW DATA GENERATED.\n";

if(!exists $args{'skip_check_rawdata'})
{
	print "Program: checkRawData.pl ...\n";
	print "Checking integrity of raw data files in $dataDir ...\n";
	$checkRawData_cmdout = `perl checkRawData.pl $dataDir`;
	print "$checkRawData_cmdout\n";
	print "=================================================\n\n";
	foreach(split(/\n/,$checkRawData_cmdout))
	{
		if($_=~m/ERROR/ || $_ =~m/WARNING/)
		{
			print "ERROR OR WARNING DURING PRELIMINARY CHECK. ENDING SCRIPT.\n\n";
			die "DIED: ERROR OR WARNING DURING PRELIMINARY CHECK. ENDING SCRIPT.\n\n";
		}
	}
}
else
{
	print "Skipped: check raw data.\n";
}
print "=================================================\n\n";

###CHECK DATABASE RELATED OPTIONS.
if(!exists $args{'database_name'} || trim($args{'database_name'}) eq ""){die "DIED: DIED: No database name given. Please specify database name using option --database_name\n";}

###CONNECT TO DATABASE SYSTEM AND CHECK IF THE DATABASE IS PRESENT OR NOT.
my $dbh = DBI->connect("DBI:mysql:database=mysql;host=$args{'mysql_host'}","$args{'mysql_uname'}", "$args{'mysql_passwd'}",{'RaiseError' => 1, 'AutoCommit' => 0});

###CHECK IF THE DATABASE NAME ALREADY EXISTS
$dbExists = 0;
$schemata = $dbh->selectall_arrayref("SELECT * FROM INFORMATION_SCHEMA.SCHEMATA");
foreach $row (@{$schemata})
{
	if(${$row}[1] eq $args{'database_name'}){$dbExists = 1;}
}

if($dbExists && !exists $args{'write_database'}){ die "DIED: DIED: Database \'$args{'database_name'}\' already exists. Please specify write_database option with overwrite or append option.\n";}
if(!$dbExists && $args{'write_database'} eq "append"){ die "DIED: DIED: Option 'write_database' must have value 'overwrite' if database does not exist.\n";}

###RECREATE DATABASE IF DATABASE DOES NOT EXIST OR write_database:overwrite OPTION SPECIFIED.
if(!$dbExists && exists $args{'write_database'})
{
	print "Database \'$args{'database_name'}\' does not exist.\n";
	print "Creating database \'$args{'database_name'}\' if not already present ...\nSQL: CREATE SCHEMA IF NOT EXISTS $args{'database_name'} DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs\n\n";
	$dbh->do("CREATE SCHEMA IF NOT EXISTS $args{'database_name'} DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs");
}
elsif($args{'write_database'} eq "overwrite")
{
	print "Deleting database \'$args{'database_name'}\' ...\nSQL: DROP SCHEMA $args{'database_name'}\n\n";
	$dbh->do("DROP SCHEMA $args{'database_name'}");

	print "Creating database \'$args{'database_name'}\' if not already present ...\nSQL: CREATE SCHEMA IF NOT EXISTS $args{'database_name'} DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs\n\n";
	$dbh->do("CREATE SCHEMA IF NOT EXISTS $args{'database_name'} DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs");
}
elsif($args{'write_database'} eq "append")
{
	print "Using log file: $args{'database_write_log'} as a restart file for appending to the existing database.\n";
}
else
{
	die "DIED: Please specify write_database option.\n";
}


$dbh->commit;
$dbh->disconnect;


#die "DIED: OK\n";

###MAKE OUTPUT DIRECTORY
print "Making directory: $outputDir ...\n\n";
$dirPath = "";
foreach (split(/\/+/,$outputDir))
{
	$dirPath .= $_."/";
	mkdir($dirPath);
}
print "=================================================\n\n";

#goto PDBTABLES;
#goto QRY;

if(!exists $args{'skip_build_tables'})
{
	#goto HBOND;
	print "Program: buildProbeTables.pl\n\n";
	$buildProbeTables_cmdout = `python buildProbeTables.py $dataDir $outputDir`;
	print "$buildProbeTables_cmdout\n";
	print "=================================================\n\n";
	#die "\nSTOPPED\n";

	print "Program: buildPiInteractionTables.py\n\n";
	$buildPiInteractionTables_cmdout = `python buildPiInteractionTables.py $dataDir $outputDir`;
	print "$buildPiInteractionTables_cmdout\n";
	print "=================================================\n\n";

	#die;

	HBOND:
	print "Program: buildHbondTables.pl\n\n";
	$buildHbondTables_cmdout = `perl buildHbondTables.pl $dataDir $outputDir`;
	print "$buildHbondTables_cmdout\n";
	print "=================================================\n\n";
	#goto END_BUILD_TABLES;

	print "Program: buildSheetAndStrandTables.pl\n\n";
	$buildSheetAndStrandTables = `perl buildSheetAndStrandTables.pl $dataDir $outputDir`;
	print "$buildSheetAndStrandTables\n";
	print "=================================================\n\n";

	PDBTABLES:
	### buildPdbTables.py DEPENDS ON buildSheetAndStrandTables.pl
	print "Program: buildPdbTables.py\n\n";
	$buildPdbTables_cmdout = `python buildPdbTables.py $dataDir $outputDir`;
	print "$buildPdbTables_cmdout\n";
	print "=================================================\n\n";

	#die "DIED: PDBTABLES DONE.\n";

	print "###DONE BUILDING TABLES.###\n\n";
}
else
{
	print "Skipped: build tables.\n";
}
END_BUILD_TABLES:
print "=================================================\n\n";
#die;


QRY:

###THE BELOW MENTIONED SECTION WRITES ALL QUERIES TO FILES SORTED BY PDB IDS.

$dataDir=~m/.+\/(.+)$/;
$insertQueries = "insertQueries_".$1.".sql";
$qryDir = $outputDir."/insertQueries";
#goto EXEQRY;

if(!exists $args{'skip_build_insert_queries'})
{
	#print "Program: getInsertQueriesByPdbId.pl\n\n";
	#print "Wrting insert queriy files in $qryDir\n";
	#print `perl getInsertQueriesByPdbId.pl $outputDir $qryDir`;

	###THE BELOW MENTIONED SECTION WRITES ALL QUERIES TO FILES SORTED BY TABLE NAMES.
#=head
	print "Program: createInsertQueries.pl\n\n";
	$dataDir=~m/.+\/(.+)$/;
	$insertQueries = "insertQueries_".$1.".sql";
	print "Redirecting console output to: $outputDir/$insertQueries\n";
	`perl createInsertQueries.pl $outputDir>$outputDir/$insertQueries`;
	print "=================================================\n\n";

	print "Program: splitInsertQueries.pl\n\n";
	print `perl splitInsertQueries.pl $args{'datadir'}/pdb $outputDir/$insertQueries $qryDir`;
	print "=================================================\n\n";
#=cut

	print "###DONE WRITING INSERT QUERIES.###\n\n";
}
else
{
	print "Skipped: build insert queries.\n";
}print "=================================================\n\n";

EXEQRY:
#die "\nDEAD\n";
###EXECUTE INSERT QUERIES.

if(!exists $args{'skip_populate_database'})
{
	print "Program: populateDatabase.pl\n\n";

	$databaseWriteLogFile = $outputDir."/".$args{'database_write_log'};
	if($args{'write_database'} eq "overwrite")
	{
		opendir(SQLDIR,$qryDir) || die "DIED: Can not open SQLDIR: $qryDir\n";

	###RECREATE EMPTY SQL LOG FILE.
		print "Recreating empty SQLLOG file ...\n";
		print	"rm $databaseWriteLogFile\n";
		`rm $databaseWriteLogFile`;
		print	"touch $databaseWriteLogFile\n";
		`touch $databaseWriteLogFile`;

	###RECREATE TABLES IF THEY DO NOT EXIST.
		print "SQL: mysql -u$args{'mysql_uname'} -p$args{'mysql_passwd'} $args{'database_name'}<$args{'recreate_tables_file'}\n";
		print `mysql -u$args{'mysql_uname'} -p$args{'mysql_passwd'} $args{'database_name'}<$args{'recreate_tables_file'}`;

		foreach $file (grep{/\.sql$/}readdir(SQLDIR))
		{
			$sqlFile = $qryDir."/".$file;
	###populateDatabase.pl SHOULD TAKE CARE OF ROLLING BACK BY DELETING INCOMPLETE ENTRY.
			$populateDatabaseOutput = `perl populateDatabase.pl $sqlFile $args{'database_name'} $args{'mysql_host'} $args{'mysql_uname'} $args{'mysql_passwd'} $databaseWriteLogFile`;
			print $populateDatabaseOutput;
			if($? == -1){die "DIED: Died in populateDatabase.pl\n*$?*\n";}
		}
		close(SQLDIR);
	}
	elsif($args{'write_database'} eq "append")
	{
	###CREATE TABLES IF THEY DO NOT EXIST.
		print "SQL: mysql -u$args{'mysql_uname'} -p$args{'mysql_passwd'} $args{'database_name'}<$args{'create_tables_file'}\n";
		print `mysql -u$args{'mysql_uname'} -p$args{'mysql_passwd'} $args{'database_name'}<$args{'create_tables_file'}`;

	###READ DATABASE WRITE LOG FILE AND DECIDE FROM WHERE TO START DATA ENTRY.
		@dataEntryDone = ();
		open(SQLLOG,$databaseWriteLogFile)||die "DIED: Can not open SQLLOG for reading: $databaseWriteLogFile\n";
		foreach $line (<SQLLOG>)
		{
			chomp $line;
			if($line=~m/^SQLFILE\t(.+?)\t(.*)/)
			{
				if(trim($2) eq "DONE"){push(@dataEntryDone,$1);}
			}
		}
		print "Excluding following files:\n".join("\n",@dataEntryDone)."\n\n";
		close(SQLLOG);

	###NEXT STEPS:
	###OPEN SQLLOG FILE IN APPEND MODE.
	###LOOP OVER qryDir FILES, FILTERING OUT THE FILES SPECIFIED IN @dataEntryDone.
	###START ENTERING THE DATA USING populateDatabase.pl. (populateDatabase.pl WILL STOP AND ROLL BACK ON DATA ENTRY ERROR.)
	###WRITE SQLLOG FILE.
	###END LOOP.
	###CLOSE SQLLOG FILE.


		opendir(SQLDIR,$qryDir) || die "DIED: Can not open SQLDIR: $qryDir\n";
		foreach $file (grep{/\.sql$/}readdir(SQLDIR))
		{
			$sqlFile = $qryDir."/".$file;
			if(!inArray($sqlFile,\@dataEntryDone,0))
			{
	###populateDatabase.pl SHOULD TAKE CARE OF ROLLING BACK BY DELETING INCOMPLETE ENTRY.
				$populateDatabaseOutput = `perl populateDatabase.pl $sqlFile $args{'database_name'} $args{'mysql_host'} $args{'mysql_uname'} $args{'mysql_passwd'} $databaseWriteLogFile`;
				print $populateDatabaseOutput;
				if($? == -1){die "DIED: Died in populateDatabase.pl\n*$?*\n";}
			}
		}

		close(SQLDIR);
	}
}
else
{
	print "Skipped: populate database.\n";
}
print "=================================================\n\n";

END:

print "\n### END SCRIPT: $0 ###\n\n";


##################################################################################

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

