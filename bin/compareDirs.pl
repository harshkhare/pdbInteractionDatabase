#!usr/bin/perl

$dir1 = "../data/input/harsh_top8000/pdbNaccess";
$dir2 = "../data/input/harsh_top8000/pdbNaccess";

$ext1 = "asa";
$ext2 = "asac";

opendir(DIR1,$dir1)||die"$!\n";
opendir(DIR2,$dir2)||die"$!\n";


%fileHash = ();

my $cnt1 = 0;
foreach $file(grep{s/(.+)\.$ext1$/$1/}readdir(DIR1))
{
	$fileHash{$file}++;
	$cnt1++;
}
print "$ext1 files: $cnt1\n";


my $cnt2 = 0;
foreach $file(grep{s/(.+)\.$ext2$/$1/}readdir(DIR2))
{
	$fileHash{$file}++;
	$cnt2++;
}
print "$ext2 files: $cnt2\n";


print "\nUnmatched files:\n";
map{if($fileHash{$_} == 1){print "$_\n";}}keys %fileHash;

closedir(DIR1);
closedir(DIR2);
