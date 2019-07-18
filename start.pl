#!usr/bin/perl

use strict;

print "\n                   ===PDB Intecation Database===\n\n";

my $opt = "";
my $optionsFile = "";
my $loginCnt = 0;
my $usersFile = "credentials/users";
my $overwrite = 0;
my $inputDir = "";
my $outputDir = "";
my $cmdout = "";
my $dbNameShort = "";
my $dbName = "";
my $standardOptionsFile = "bin/buildPdbInteractionTables_options_standard";

my $server_ip = `ip a s eth0 | awk '/inet / {print\$2}' | cut -d/ -f1`; chomp $server_ip;
my $server_name = `echo \$USER`; chomp $server_name;
my $working_dir = `pwd`; chomp $working_dir;

my $user_ip = `echo \$SSH_CLIENT`; chomp $user_ip;
$user_ip=~s/(.+?)\s.*/$1/;

print "You are connecting from $user_ip\n";
USER_NAME:
print "Enter user name (without preceding or trailing spaces): "; my $username = lc<STDIN>; chomp $username;
if($username=~m/[\s|\t]/g || $username eq ""){print "User name can not contain blank characters.\n"; goto USER_NAME;}
open(USERS,$usersFile)||die"Can not open USERS.\n";
my %userInfo = ();
foreach my $line(<USERS>){chomp $line; $line=~m/^(.+)\t(\d+).*/; $userInfo{$1} = {"LOGIN_CNT"=>$2};}
close(USERS);
$userInfo{$username}{"LOGIN_CNT"}++;

print "\nWelcome $username!\n";
if($userInfo{$username}{"LOGIN_CNT"} == 1)
{
	print "This seems to be your first login. You have been added to the user list.\nYou can use this user name for future logins.\n";
}
else
{
	print "This is your $userInfo{$username}{'LOGIN_CNT'}".getNumberSuffix($userInfo{$username}{'LOGIN_CNT'})." login."
}

open(USERS,">".$usersFile)||die"Can not open USERS in write mode.\n";
map{print USERS "$_\t$userInfo{$_}{'LOGIN_CNT'}\n";}sort {$a cmp $b} keys %userInfo;
close(USERS);

print "\n\nPress <Enter> or <Return> to continue..."; <STDIN>;

print "\n\n*** SOME IMPORTANT INSTRUCTIONS. READ CAREFULLY! ***\n";
print "Your user name will be used as prefix to the database name.\nThis helps in proper identification and segregation of databases.\n";
print "As this database is limited only to our lab, it has not been\nmade secure enough; hoping that the users will take care while using it.\n";
print "The default user name and password for MySQL gives you\nentire access and it is your responsibility\nthat any data is not accidentally deleted.\n";
print "\n====================================================\n\n";

print "Press <Enter> or <Return> to accept the terms and conditions of\nusage of this program and continue..."; <STDIN>;

DB_NAME:
print "\nPlease specify the name of the database: ";
while(1)
{
	$dbNameShort = <STDIN>; chomp $dbNameShort; trim($dbNameShort);
	if($dbNameShort=~m/[\s|\t]/g || $dbNameShort eq ""){print "Database name can not contain blank characters."; goto DB_NAME;}
	$inputDir = "data/input/$username"."_$dbNameShort";
	$outputDir = "data/output/$username"."_$dbNameShort";
	$dbName = $username."_$dbNameShort";
	if(-d $inputDir)
	{
		print "Database/directory exists. Do you want to overwrite it?[y/n]";
		OVERWRITE:
		my $opt = lc(<STDIN>); chomp $opt;
		if($opt eq 'n'){print "Please give another name for the database.\n";}
		elsif($opt eq 'y')
		{
			`rm -r $inputDir`; print "Directory $inputDir deleted.\n";
			mkdir($inputDir); print "Directory $inputDir created.\n";
			$overwrite = 1;  #print "Database overwrite flag turned ON.\n";
			last;
		}
		else{print "Please specify a valid option.\n"; goto OVERWRITE;}
	}
	else{mkdir($inputDir); print "Directory $inputDir is created.\n"; last;}
}

###MAKE OUTPUT DIRECTORY
print "\nMaking output directory: $outputDir ...\n";
`mkdir -p $outputDir`;

mkdir("$inputDir/pdb");
print "\nDirectory $inputDir/pdb is created.\n";
print "\nNow you need to transfer the pdb files to $server_name"."@".$server_ip.":$working_dir/$inputDir/pdb\n";
print "\nEnter your user name of your computer: "; my $client_username = <STDIN>; chomp $client_username;
print "\nEnter the full path of the directory in which\nthe pdb files are stored on your computer: ";
USER_PDBDIR:
my $user_pdbDir = <STDIN>; chomp $user_pdbDir;

print "\nChecking if the specified directory exists ...\n";
my $dirExistsCmd = "ssh $client_username@"."$user_ip test -d $user_pdbDir && echo exists";
my $dirExists = `$dirExistsCmd`; chomp $dirExists;
if($dirExists ne "exists")
{
	print "\nRemote directory $client_username@".$user_ip.":$user_pdbDir does not exist.\nPlease give the correct path.\n";
	goto USER_PDBDIR;
}

print "\nDirectory found.\n\nTransferring contents of $client_username@".$user_ip.":$user_pdbDir to $inputDir/pdb/ ...\n";
my $scp_path = "$client_username@".$user_ip.":$user_pdbDir";
system("sh scp.sh $scp_path/* $inputDir/pdb/ $client_username $user_ip $user_pdbDir");

print "Files transferred successfully.\n----------------------------------------------------\n";

print "\nYou are almost ready to go now! The last step is to build the options file.\n";
print "\nEnter options file's full path on your computer or accept default by pressing return [$standardOptionsFile]: ";
OPTIONS_FILE:
my $userOptionsFile = <STDIN>; chomp $userOptionsFile;
my $finalOptionsFile = "$inputDir/$username"."_$dbNameShort.options";
if($userOptionsFile eq ""){buildOptionsFile($standardOptionsFile,$finalOptionsFile);}
else
{
	print "\nChecking if the specified file exists ...\n";
	my $optionsFileExists = "ssh $client_username@"."$user_ip test -e $userOptionsFile && echo exists";
	$optionsFileExists = `$optionsFileExists`; chomp $optionsFileExists;
	if($optionsFileExists ne "exists")
	{
		print "File not found. Enter valid filepath: "; goto OPTIONS_FILE;
	}
	else
	{
		print "\nCopying $client_username@".$user_ip.":$userOptionsFile to $finalOptionsFile ...\n";
		my $scp_path = "$client_username@".$user_ip.":$userOptionsFile";
		`scp $scp_path $finalOptionsFile`;
	}
}

print "\nThe options file has been generated. Do you want to view and edit it in gedit?[y/n]";
EDIT_OPTIONS:
my $editOptionsFile = lc(<STDIN>); chomp $editOptionsFile;
if($editOptionsFile eq 'y'){`gedit $finalOptionsFile`;}
elsif($editOptionsFile ne 'n'){print "Invalid option. Enter correct option: "; goto EDIT_OPTIONS;}

print "\n\n====================================================\n";
print "Congratulations!!! You can now submit the job.\n";
print "Press <Enter> or <Return> to continue to the final step..."; <STDIN>;

RUN:
print "Do you want to run the job now? [y/n]: ";
my $run = lc(<STDIN>); chomp $run;
my $logFile = "$outputDir/$username"."_$dbNameShort.log";
if($run eq 'y'){$cmdout = run("../$finalOptionsFile","../$logFile"); print "\n-----------\n$cmdout\n-----------\n";}
elsif($run ne 'n'){print "Invalid option.\n"; goto RUN;}
else{print "Exiting without running the job.\n"; exit(0);}

print "Done.\n";
print "The program will now quit. You can check if the data generated is correct.\n";
print "Check log file for details of the job. ($logFile)\n";
print "Your raw data is stored in $outputDir\n";
print "Database can be accessed in web browser at http://$server_ip/phpmyadmin\n\n";

exit(1);


############################################################################################

sub buildOptionsFile
{
	my($standardOptionsFile, $optionsFile) = @_;
	my %args = ();

	if(! -e $standardOptionsFile){die "File $standardOptionsFile not found.\n";}
	else
	{
		open(OPTIONS_STANDARD,$standardOptionsFile)||die"Can not open OPTIONS_STANDARD.\n";
		foreach (<OPTIONS_STANDARD>)
		{
			chomp;
			if($_=~/^(#?)-+(.+)/)
			{
				#$_=~s/-+(.+)/$1/;
				my @arg = split(/\s/,$2);
				my $arg = shift @arg;
				my $value = join(" ",@arg);
				#print "--file => $arg : $value\n";
				$args{$arg} = {"VALUE"=>$value, "COMMENT"=>$1};
			}
		}
		close(OPTIONS_STANDARD);
	}

	$args{"datadir"}{"VALUE"} = "../".$inputDir;
	$args{"outputdir"}{"VALUE"} = "../".$outputDir;
	$args{"database_name"}{"VALUE"} = $dbName;

	open(OPTIONS,">$optionsFile")||die "Can not open OPTIONS file for writing.\n";
	map{print OPTIONS "$args{$_}{'COMMENT'}--$_ $args{$_}{'VALUE'}\n";}sort{$a cmp $b}keys %args;
	close(OPTIONS);
}

sub run
{
	my($optionsFile,$logFile) = @_;
	print "Running program buildPdbInteractionTables_serial\n";
	print "Options file: $optionsFile\n";
	print "Log file: $logFile\n\n";
	print "CMD: bin/buildPdbInteractionTables_serial --file $optionsFile>$logFile\n\n";
	my $cmdout = `sh runJob.sh $optionsFile $logFile`;
	#my $cmdout = `perl bin/buildPdbInteractionTables_serial.pl --file $optionsFile>$logFile`;

	return($cmdout);
}

sub trim
{
	my $str = $_[0];
	$str=~s/^\s*(.*)/$1/;
	$str=~s/\s*$//;
	return $str;
}

sub getNumberSuffix
{
	if($_[0]=~m/1$/ && $_[0]!~m/11$/){return "st";}
	elsif($_[0]=~m/2$/ && $_[0]!~m/12$/){return "nd";}
	elsif($_[0]=~m/3$/ && $_[0]!~m/13$/){return "rd";}
	else{return "th";}
}


