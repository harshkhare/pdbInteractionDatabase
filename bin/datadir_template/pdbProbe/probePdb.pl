#!usr/bin/perl

use strict;

my $pdbInDir = "../pdb";

opendir(PDBINDIR,$pdbInDir)||die"Can not open PDBINDIR.\n";

foreach my $file(grep{/\.pdb$/}readdir(PDBINDIR))
{
###ASSUME THAT HYDROGENS ARE ALREADY ADDED TO THESE FILES.

	$file=~m/(.+)\.pdb$/;
	my $pdbid = $1;
	print `echo \$PID_MOLPROBITY_PATH`."/probe -Unformated all $pdbInDir/$file\n";
	my $probeOutput = `\$PID_MOLPROBITY_PATH/probe -Unformated all $pdbInDir/$file`;
	#`probe_linux225 -Unformated all $pdbInDir/$file>probe.out`;

#:1->1:wc: A2236 HOH  O   : A 197 ARG  NH1 :0.098:0.349:28.705:47.313:-10.910:0.000:0.0089:O:N:28.705:47.313:-10.910:24.40:23.54
#:1->1:wc: A2236 HOH  O   : A 197 ARG  NH1 :0.098:0.330:27.757:47.635:-10.896:0.000:0.0110:O:N:27.757:47.635:-10.896:24.40:23.54
#:1->1:wc: A2236 HOH  O   : A 197 ARG  NH1 :0.098:0.367:28.252:47.306:-10.657:0.000:0.0072:O:N:28.252:47.306:-10.657:24.40:23.54
#:1->1:wc: A2236 HOH  O   : A 197 ARG  NH1 :0.098:0.377:28.012:47.399:-10.652:0.000:0.0064:O:N:28.012:47.399:-10.652:24.40:23.54
#:1->1:wc: A2236 HOH  O   : A 194 GLU  CG  :0.458:0.482:28.753:50.022:-10.279:0.000:0.0015:O:C:28.753:50.022:-10.279:24.40:37.66
#:1->1:wc: A2236 HOH  O   : A 197 ARG  CG  :0.398:0.453:27.960:47.458:-10.137:0.000:0.0024:O:C:27.960:47.458:-10.137:24.40:21.05
#:1->1:wc: A2236 HOH  O   : A 197 ARG  CG  :0.398:0.408:27.751:47.607:-10.131:0.000:0.0043:O:C:27.751:47.607:-10.131:24.40:21.05
#:1->1:wc: A   1 MET  CA  : A 400 HOH  O   :0.380:0.409:0.945:-10.638:21.605:0.000:0.0043:C:O:0.945:-10.638:21.605:33.19:35.41
#     name:pat:type:srcAtom:targAtom:mingap:gap:spX:spY:spZ:spikeLen:score:stype:ttype:x:y:z:sBval:tBval:

	my %contactHash = ();
	foreach my $line(split("\n",$probeOutput))
	{
		#$line=~s/^\:(.+)/$1/g;
		if($line=~m/.*?\:.+?\:(.+?)\:(.+?)\:(.+?)\:(.+?)\:(.+?)\:.+?\:.+?\:.+?\:.+?\:(.+?)\:.*/)
		{
#			print "$line\n";
#			print "$1,$2,$3,$4,$5,$6\n";
			if   (exists $contactHash{$1}{$2}{$3}){ push @{$contactHash{$1}{$2}{$3}},{'MINGAP'=>$4,'GAP'=>$5,'SCORE'=>$6,'LINE'=>$line};}
			elsif(exists $contactHash{$1}{$3}{$2}){ push @{$contactHash{$1}{$3}{$2}},{'MINGAP'=>$4,'GAP'=>$5,'SCORE'=>$6,'LINE'=>$line};}
			else                                  { push @{$contactHash{$1}{$2}{$3}},{'MINGAP'=>$4,'GAP'=>$5,'SCORE'=>$6,'LINE'=>$line};}
		}
	}

	open(PROBEOUT,">$pdbid.probe")||die "Can not open PROBEOUT for writing.\n";

	foreach my $type(sort keys %contactHash)
	{
		foreach my $k1(sort keys %{$contactHash{$type}})
		{

			if(@{[keys %{$contactHash{$type}{$k1}}]} > 0)
			{
				foreach my $k2(sort keys $contactHash{$type}{$k1})
				{
					#print "$type:$k1<=>$k2: ".@{$contactHash{$type}{$k1}{$k2}}."\n";

### cc,wc: PREFER HIGHER SCORE AND LOWER GAP
### hb:    PREFER HIGHER SCORE AND LOWER GAP
### so,bo: PREFER LOWER  SCORE AND LOWER GAP

					if($type eq 'cc' or $type eq 'wc' or $type eq 'hb')
					{
						my @arr = sort {${$a}{'SCORE'}-${$a}{'GAP'} <=> ${$b}{'SCORE'}-${$b}{'GAP'}}@{$contactHash{$type}{$k1}{$k2}};
						print PROBEOUT "${$arr[$#arr]}{'LINE'}\n";
					}

					if($type eq 'bo' or $type eq 'so')
					{
						my @arr = sort {${$a}{'SCORE'}+${$a}{'GAP'} <=> ${$b}{'SCORE'}+${$b}{'GAP'}}@{$contactHash{$type}{$k1}{$k2}};
						print PROBEOUT "${$arr[0]}{'LINE'}\n";
					}

					#@k = split("-",$k);
					#$tempHash{$k[0]."-".$k[1]."-".$k[2]}++;
				}
				#@keys = keys %{$contactHash{$k1}};
				#print "*$k1 ".@keys." =@keys*\n";
			}
		}
	}
	close(PROBEOUT);
}





sub trim
{
	my $str = $_[0];
	$str=~s/^\s*(.*)/$1/;
	$str=~s/\s*$//;
	return $str;
}

