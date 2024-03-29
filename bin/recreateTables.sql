DROP TABLE IF EXISTS `probe`;
DROP TABLE IF EXISTS `hbond`;
DROP TABLE IF EXISTS `xhpi`;
DROP TABLE IF EXISTS `cho`;
DROP TABLE IF EXISTS `pipi`;
DROP TABLE IF EXISTS `cationpi`;
DROP TABLE IF EXISTS `cation`;
DROP TABLE IF EXISTS `ring`;
DROP TABLE IF EXISTS `xh`;
DROP TABLE IF EXISTS `resSheetStrandLink`;
DROP TABLE IF EXISTS `strand`;
DROP TABLE IF EXISTS `sheet`;
DROP TABLE IF EXISTS `missingres`;
DROP TABLE IF EXISTS `missingatom`;
DROP TABLE IF EXISTS `modres`;
DROP TABLE IF EXISTS `het`;
DROP TABLE IF EXISTS `atom`;
DROP TABLE IF EXISTS `residue`;
DROP TABLE IF EXISTS `hetinfo`;
DROP TABLE IF EXISTS `chain`;


create table IF NOT EXISTS chain
(
	pdb_id varchar(50),
	chain_id varchar(1),
	atom_num_res smallint,
	hetatm_num_res smallint,
	num_atoms mediumint,
	num_hetatms int(6),
	asa_all float(8,3),
	asa_sc float(8,3),
	asa_mc float(8,3),
	asa_np float(8,3),
	asa_p float(8,3),
	asac_all float(8,3),
	asac_sc float(8,3),
	asac_mc float(8,3),
	asac_np float(8,3),
	asac_p float(8,3),
	seq text,
	len smallint,
	primary key (pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS residue
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	res_name varchar(3),
	ben_symbol varchar(1),
	bp1 varchar(5),
	bp2 varchar(5),
	dssp_sec_struct varchar(1),
	dssp_sec_struct_info varchar(8),
	phi float(6,3),
	psi float(6,3),
	tco float(4,3),
	kappa float(4,1),
	alpha float(4,1),
	rsa_all_abs float(6,3),
	rsa_all_rel float(6,3),
	rsa_sc_abs float(6,3),
	rsa_sc_rel float(6,3),
	rsa_mc_abs float(6,3),
	rsa_mc_rel float(6,3),
	rsa_np_abs float(6,3),
	rsa_np_rel float(6,3),
	rsa_p_abs float(6,3),
	rsa_p_rel float(6,3),
	rsac_all_abs float(6,3),
	rsac_all_rel float(6,3),
	rsac_sc_abs float(6,3),
	rsac_sc_rel float(6,3),
	rsac_mc_abs float(6,3),
	rsac_mc_rel float(6,3),
	rsac_np_abs float(6,3),
	rsac_np_rel float(6,3),
	rsac_p_abs float(6,3),
	rsac_p_rel float(6,3),
	primary key (pdb_id,chain_id,res_num),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

create table IF NOT EXISTS missingres
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	res_name varchar(3),
	primary key (pdb_id,chain_id,res_num),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

create table IF NOT EXISTS modres
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	res_name varchar(3),
	std_res_name varchar(3),
	description varchar(200),
	primary key (pdb_id,chain_id,res_num),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS hetinfo
(
	pdb_id varchar(50),
	res_name varchar(3),
	chem_name varchar(200),
	chem_name_syn varchar(200),
	formula varchar(200),
	comp_num smallint,
	primary key (pdb_id,res_name)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS het
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	res_name varchar(3),
	num_hetatm mediumint,
	description varchar(200),
	primary key (pdb_id,chain_id,res_num),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num),
	foreign key (pdb_id,res_name) references hetinfo(pdb_id,res_name)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS atom
(
	pdb_id varchar(50),
	atom_num mediumint,
	alt_loc varchar(1),
	tag varchar(6),
	chain_id varchar(1),
	res_num varchar(5),
	atom_name varchar(4),
	x float(6,3),
	y float(6,3),
	z float(6,3),
	ocp float(5,2),
	b_fact float(5,2),
	element varchar(2),
	charge varchar(2),
	asa float(6,3),
	asac float(6,3),
	primary key (pdb_id,atom_num,alt_loc),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

create table IF NOT EXISTS missingatom
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	res_name varchar(3),
	atom_name varchar(4),
	primary key (pdb_id,chain_id,res_num,atom_name),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;

create table IF NOT EXISTS strand
(
	pdb_id varchar(50),
	chain_id varchar(1),
	sheet_id varchar(2),
	strand_id tinyint,
	strand_seq varchar(300),
	strand_seq_aa varchar(200),
	num_total_res tinyint,
	edge_res varchar(300),
	num_edge_res tinyint,
	fraction_edge float(4,3),
	bulge_res varchar(300),
	num_bulge_res tinyint,
	fraction_bulge float(4,3),
	num_bulges tinyint,
	burried_res varchar(300),
	num_burried_res tinyint,
	fraction_burried_res float(4,3),
	symbol_seq varchar(100),
	seq varchar(100),
	parallel varchar(20),
	antiparallel varchar(20),
	primary key (pdb_id,chain_id,sheet_id,strand_id),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS sheet
(
	pdb_id varchar(50),
	chain_id varchar(1),
	sheet_id varchar(2),
	strands varchar(100),
	num_strands tinyint,
	primary key (pdb_id,chain_id,sheet_id),
	foreign key (pdb_id,chain_id) references chain(pdb_id,chain_id)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS resSheetStrandLink
(
	pdb_id varchar(50),
	chain_id varchar(1),
	res_num varchar(5),
	sheet_id varchar(2),
	strand_id tinyint,
	foreign key (pdb_id,chain_id,sheet_id) references sheet(pdb_id,chain_id,sheet_id),
	foreign key (pdb_id,chain_id,sheet_id,strand_id) references strand(pdb_id,chain_id,sheet_id,strand_id),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS cation
(
	pdb_id varchar(50),
	cationid smallint,
	chain_id varchar(1),
	res_num varchar(5),
	cation_atom_nums varchar(50),
	alt_loc varchar(1),
	cen_x float(6,3),
	cen_y float(6,3),
	cen_z float(6,3),
	primary key (pdb_id,cationid),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS ring
(
	pdb_id varchar(50),
	ringid smallint,
	chain_id varchar(1),
	res_num varchar(5),
	ring_atom_nums varchar(50),
	alt_loc varchar(1),
	cen_x float(6,3),
	cen_y float(6,3),
	cen_z float(6,3),
	ring_normal varchar(50),
	primary key (pdb_id,ringid),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS xh
(
	pdb_id varchar(50),
	xhid mediumint,
	chain_id varchar(1),
	res_num varchar(5),
	x_atom_name varchar(4),
	x_atom_num mediumint,
	h_atom_name varchar(4),
	h_atom_num mediumint,
	alt_loc varchar(1),
	primary key (pdb_id,xhid),
	foreign key (pdb_id,chain_id,res_num) references residue(pdb_id,chain_id,res_num),
	foreign key (pdb_id,x_atom_num,alt_loc) references atom(pdb_id,atom_num,alt_loc),
	foreign key (pdb_id,h_atom_num,alt_loc) references atom(pdb_id,atom_num,alt_loc)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS pipi
(
	pdb_id varchar(50),
	ringid1 smallint,
	ringid2 smallint,
	cen_cen_dist float(6,3),
	pin_pin_angle float(6,3),
	close_atom1 mediumint,
	close_atom2 mediumint,
	closest float(6,3),
	alt_loc1 varchar(1),
	far_atom1 mediumint,
	far_atom2 mediumint,
	farthest float(6,3),
	alt_loc2 varchar(1),
	primary key (pdb_id,ringid1,ringid2),
	foreign key (pdb_id,ringid1) references ring(pdb_id,ringid),
	foreign key (pdb_id,ringid2) references ring(pdb_id,ringid),
	foreign key (pdb_id,close_atom1,alt_loc1) references atom(pdb_id,atom_num,alt_loc),
	foreign key (pdb_id,close_atom2,alt_loc2) references atom(pdb_id,atom_num,alt_loc),
	foreign key (pdb_id,far_atom2,alt_loc1) references atom(pdb_id,atom_num,alt_loc),
	foreign key (pdb_id,far_atom2,alt_loc2) references atom(pdb_id,atom_num,alt_loc)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS xhpi
(
	pdb_id varchar(50),
	xhid mediumint,
	ringid smallint,
	x_pim float(6,3),
	h_pim float(6,3),
	x_h_pim float(6,3),
	x_pim_pin float(6,3),
	primary key(pdb_id,xhid,ringid),
	foreign key (pdb_id,xhid) references xh(pdb_id,xhid),
	foreign key (pdb_id,ringid) references ring(pdb_id,ringid)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS cationpi
(
	pdb_id varchar(50),
	cationid smallint,
	ringid smallint,
	cat_pim float(6,3),
	cat_pim_pin float(6,3),
	primary key(pdb_id,cationid,ringid),
	foreign key (pdb_id,cationid) references cation(pdb_id,cationid),
	foreign key (pdb_id,ringid) references ring(pdb_id,ringid)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS hbond
(
	pdb_id varchar(50),
	hbond_num smallint,
	donor_chain_id varchar(1),
	donor_resnum varchar(5),
	donor_resname varchar(3),
	donor_atname varchar(4),
	acceptor_chain_id varchar(1),
	acceptor_resnum varchar(5),
	acceptor_resname varchar(3),
	acceptor_atname varchar(4),
	donor_cat varchar(1),
	acceptor_cat varchar(1),
	d_a_dist float(3,2),
	aas varchar(3),
	ca_ca_dist float(3,2),
	d_h_a_angle float(4,1),
	h_a_dist float(3,2),
	h_a_aa_angle float(4,1),
	d_a_aa_angle float(4,1),
	primary key (pdb_id,hbond_num),
	foreign key (pdb_id,donor_chain_id,donor_resnum) references residue(pdb_id,chain_id,res_num),
	foreign key (pdb_id,acceptor_chain_id,acceptor_resnum) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS cho
(
	pdb_id varchar(50),
	xhid mediumint,
	o_chain_id varchar(1),
	o_res_num varchar(5),
	o_atom_num mediumint,
	o_alt_loc varchar(1),
	c_o float(6,3),
	h_o float(6,3),
	c_h_o float(6,3),
	h_o_c float(6,3),
	primary key (pdb_id,xhid,o_chain_id,o_res_num,o_alt_loc),
	foreign key (pdb_id,xhid) references xh(pdb_id,xhid),
	foreign key (pdb_id,o_chain_id,o_res_num) references residue(pdb_id,chain_id,res_num),
	foreign key (pdb_id,o_atom_num,o_alt_loc) references atom(pdb_id,atom_num,alt_loc)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


create table IF NOT EXISTS probe
(
	pdb_id varchar(50),
	probe_id mediumint,
	chain1 varchar(1),
	res_num1 varchar(5),
	atom_num1 mediumint,
	alt_loc1 varchar(1),
	chain2 varchar(1),
	res_num2 varchar(5),
	atom_num2 mediumint,
	alt_loc2 varchar(1),
	type varchar(2),
	mingap float(5,3),
	gap float(5,3),
	score float(6,4),
	primary key (pdb_id,probe_id),
	foreign key (pdb_id,chain1) references chain(pdb_id,chain_id),
	foreign key (pdb_id,chain2) references chain(pdb_id,chain_id),
	foreign key (pdb_id,chain1,res_num1) references residue(pdb_id,chain_id,res_num),
	foreign key (pdb_id,chain2,res_num2) references residue(pdb_id,chain_id,res_num)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 COLLATE=latin1_general_cs;


