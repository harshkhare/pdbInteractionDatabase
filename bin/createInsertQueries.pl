#!usr/bin/perl


###GLOBAL VARIABLES

$tableDir = $ARGV[0];

###DATA TYPES
@numeric = ('atom_num_res','hetatm_num_res','num_atoms','num_hetatms','atom_num','x','y','z','ocp','b_fact','strand_id','num_total_res','num_edge_res','fraction_edge','num_bulge_res','fraction_bulge','num_bulges','num_burried_res','fraction_burried_res','num_strands','strand_id','ringid','xhid','x_atom_num','h_atom_num','ringid1','ringid2','cen_cen_dist','pin_pin_angle','closest','farthest','xhid','ringid','x_pim','h_pim','x_h_pim','x_pim_pin','hbond_num','d_a_dist','ca_ca_dist','d_h_a_angle','h_a_dist','h_a_aa_angle','d_a_aa_angle','c_o','h_o','c_h_o','h_o_c','phi','psi','o_atom_num','cationid','cat_pim','cat_pim_pin','num_hetatm','comp_num','rsa_all_abs','rsa_all_rel','rsa_sc_abs','rsa_sc_rel','rsa_mc_abs','rsa_mc_rel','rsa_np_abs','rsa_np_rel','rsa_p_abs','rsa_p_rel','asa_all','asa_sc','asa_mc','asa_np','asa_p','asa','atom1_num','atom2_num','mingap','gap','score','tco','kappa','alpha','seq','cen_x','cen_y','cen_z','close_atom1','close_atom2','far_atom1','far_atom2','probe_id');
@varchar = ('pdb_id','chain_id','pdb_id','chain_id','res_num','res_name','ben_symbol','pdb_id','tag','chain_id','res_num','atom_name','element','charge','pdb_id','chain_id','sheet_id','strand_seq','strand_seq_aa','edge_res','bulge_res','burried_res','symbol_seq','seq','parallel','antiparallel','pdb_id','chain_id','sheet_id','strands','pdb_id','chain_id','res_num','sheet_id','pdb_id','chain_id','res_num','ring_atom_nums','centroid','ring_normal','pdb_id','chain_id','res_num','x_atom_name','h_atom_name','pdb_id','pdb_id','pdb_id','donor_chain_id','donor_resnum','donor_resname','donor_atname','acceptor_chain_id','acceptor_resnum','acceptor_resname','acceptor_atname','donor_cat','acceptor_cat','aas','o_chain_id','o_res_num','alt_loc','dssp_sec_struct','cation_atom_nums','std_res_name','description','chem_name','chem_name_syn','formula','chain1','chain2','resnum1','resnum2','atom1_name','atom2_name','type','dssp_sec_struct_info','len','alt_loc1','alt_loc2','o_alt_loc','res_num1','res_num2','bp1','bp2');
@notrim = ('dssp_sec_struct_info','alt_loc','dssp_sec_struct','seq','alt_loc1','alt_loc2','o_alt_loc');

###PARAMETERS
my $numInsertAtOnce = 1;
my $commitAfter = 1;



####################################################
my $insertQryCnt = 0;

if($commitAfter != 1)
{
	print "SET autocommit=0;\n\n";
}

printInsertIntoQueries("$tableDir/chainTable");
print "\n";
printInsertIntoQueries("$tableDir/hetinfoTable");
print "\n";
printInsertIntoQueries("$tableDir/residueTable");
print "\n";
printInsertIntoQueries("$tableDir/missingresTable");
print "\n";
printInsertIntoQueries("$tableDir/modresTable");
print "\n";
printInsertIntoQueries("$tableDir/hetTable");
print "\n";
printInsertIntoQueries("$tableDir/atomTable");
print "\n";
printInsertIntoQueries("$tableDir/missingatomTable");
print "\n";
printInsertIntoQueries("$tableDir/strandTable_formatted");
print "\n";
printInsertIntoQueries("$tableDir/sheetTable");
print "\n";
printInsertIntoQueries("$tableDir/resSheetStrandLinkTable");
print "\n";
printInsertIntoQueries("$tableDir/cationTable");
print "\n";
printInsertIntoQueries("$tableDir/ringTable");
print "\n";
printInsertIntoQueries("$tableDir/xhTable");
print "\n";
printInsertIntoQueries("$tableDir/pipiTable");
print "\n";
printInsertIntoQueries("$tableDir/xhpiTable");
print "\n";
printInsertIntoQueries("$tableDir/cationpiTable");
print "\n";
printInsertIntoQueries("$tableDir/hbondTable");
print "\n";
printInsertIntoQueries("$tableDir/choTable");
print "\n";
printInsertIntoQueries("$tableDir/probeTable");
print "\n";

if($commitAfter != 1)
{
	print "COMMIT;\n";
	print "SET autocommit=1;\n";
}
#####################################################################

sub printInsertIntoQueries
{
	my $tableFile = $_[0];

	$tableFile=~m/.+\/(.+)Table.*$/;
	my $tableName = $1;

	open(TABLE,$tableFile)||print "#ERROR: Can not open TABLE : $tableFile\n";

	$cnt = 0;
	foreach $line(<TABLE>)
	{
		chomp($line);
		if($line=~m/\t$/){$line .= " ";}
		@line = split(/\t/,$line);
		#print @line.": ".join("*",@line)."\n";
		if($cnt == 0)
		{
			@varcharCols = ();
			@notrimCols = ();
			for(my $i=0;$i<@line;$i++)
			{
				if(inArray(lc($line[$i]),\@varchar,0))
				{
					push(@varcharCols,$i);
				}
				if(inArray(lc($line[$i]),\@notrim,0))
				{
					push(@notrimCols,$i);
				}

			}
		}
		else
		{
			my $qry = "(";
#			$qry .= "INSERT INTO $tableName VALUES ";

			for(my $i=0;$i<@line;$i++)
			{
				if(inArray($i,\@varcharCols,1))
				{
					if(inArray($i,\@notrimCols,1)){	$value = $line[$i];	}
					else                          {	$value = trim($line[$i]); }
					$value=~s/'/\\'/g;
					$qry .= "\'".$value."\', ";
				}
				else
				{
					if(trim($line[$i]) eq ""){$qry .= "null, ";}
					else{$qry .= trim($line[$i]).", ";}
				}
			}
			#print "$qry*\n";
			$qry=~s/(.+),\s$/$1/;
			#print "$qry>\n";
			$qry .= ")";
			#print "$qry\n";
			push(@qrys,$qry);

			#print ">".@qrys."\n";
			if($#qrys+1 == $numInsertAtOnce)
			{
				print "INSERT INTO $tableName VALUES ".join(",",@qrys).";\n";
				$insertQryCnt++;
				if($commitAfter != 1 && !($insertQryCnt % $commitAfter))
				{
					print "\nCOMMIT;\n\n";
				}
				@qrys = ();
			}


		}
		$cnt++;
	}

	if($#qrys != -1)
	{
		print "INSERT INTO $tableName VALUES ".join(",",@qrys).";\n";
		@qrys = ();
	}
	close(TABLE);
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

