import naccess
import pdb3
import dssp
import glob
import re
from collections import defaultdict
import sys

indir = sys.argv[1]+"/pdb"

dsspdir = sys.argv[1]+"/pdbDssp"

naccessdir = sys.argv[1]+"/pdbNaccess"

tablesOutDir = sys.argv[2]

strandTable = "strandTable_formatted"

atomTable = "atomTable"
resTable = "residueTable"
chainTable = "chainTable"
missingResTable = "missingresTable"
missingAtomTable = "missingatomTable"
modresTable = "modresTable"
hetTable = "hetTable"
hetinfoTable = "hetinfoTable"

#print "***"+dsspdir

strandTableFile = open(tablesOutDir+"/"+strandTable,'r')

resHash = defaultdict()

line = ""
cnt = 0;
for line in strandTableFile.readlines():
	if cnt != 0:
		cols = line.split("\t")
		#print cols[0],cols[1]
		strand = cols[4].split(",")

		#print strand
		symbol = ''
		for res in strand:
			matchObj = re.match(r'(.)(.+?)([\*\^]?)$',res,re.S)

			if matchObj.group(3) == '^':
				symbol = 'B'
			elif matchObj.group(3) == '*':
				symbol = 'E'
			else:
				symbol = 'N'

			resHash[cols[0]+'_'+cols[1]+'_'+matchObj.group(2)] = symbol

#			print matchObj.group(1),matchObj.group(2),matchObj.group(3),symbol

	cnt += 1

strandTableFile.close()
#for key in resHash.keys():
#	print key,resHash[key]


print "Writing tables: atomTable, resTable, chainTable ...\n"

atomTableFile = open(tablesOutDir+"/"+atomTable,'w')
resTableFile = open(tablesOutDir+"/"+resTable,'w')
chainTableFile = open(tablesOutDir+"/"+chainTable,'w')
missingResTableFile = open(tablesOutDir+"/"+missingResTable,'w')
missingAtomTableFile = open(tablesOutDir+"/"+missingAtomTable,'w')
modresTableFile = open(tablesOutDir+"/"+modresTable,'w')
hetTableFile = open(tablesOutDir+"/"+hetTable,'w')
hetinfoTableFile = open(tablesOutDir+"/"+hetinfoTable,'w')

atomTableFile.write("PDB_ID\tATOM_NUM\tALT_LOC\tTAG\tCHAIN_ID\tRES_NUM\tATOM_NAME\tX\tY\tZ\tOCP\tB_FACT\tELEMENT\tCHARGE\tASA\tASAC\n")
resTableFile.write("PDB_ID\tCHAIN_ID\tRES_NUM\tRES_NAME\tBEN_SYMBOL\tBP1\tBP2\tDSSP_SEC_STRUCT\tDSSP_SEC_STRUCT_INFO\tPHI\tPSI\tTCO\tKAPPA\tALPHA\tRSA_ALL_ABS\tRSA_ALL_REL\tRSA_SC_ABS\tRSA_SC_REL\tRSA_MC_ABS\tRSA_MC_REL\tRSA_NP_ABS\tRSA_NP_REL\tRSA_P_ABS\tRSA_P_REL\tRSAC_ALL_ABS\tRSAC_ALL_REL\tRSAC_SC_ABS\tRSAC_SC_REL\tRSAC_MC_ABS\tRSAC_MC_REL\tRSAC_NP_ABS\tRSAC_NP_REL\tRSAC_P_ABS\tRSAC_P_REL\n")
chainTableFile.write("PDB_ID\tCHAIN_ID\tATOM_NUM_RES\tHETATM_NUM_RES\tNUM_ATOMS\tNUM_HETATMS\tASA_ALL\tASA_SC\tASA_MC\tASA_NP\tASA_P\tASAC_ALL\tASAC_SC\tASAC_MC\tASAC_NP\tASAC_P\tSEQ\tLEN\n")
missingResTableFile.write("PDB_ID\tCHAIN_ID\tRES_NUM\tRES_NAME\n")
missingAtomTableFile.write("PDB_ID\tCHAIN_ID\tRES_NUM\tRES_NAME\tATOM_NAME\n")
modresTableFile.write("PDB_ID\tCHAIN_ID\tRES_NUM\tRES_NAME\tSTD_RES_NAME\tDESCRIPTION\n")
hetTableFile.write("PDB_ID\tCHAIN_ID\tRES_NUM\tRES_NAME\tNUM_HETATM\tDESCRIPTION\n")
hetinfoTableFile.write("PDB_ID\tRES_NAME\tCHEM_NAME\tCHEM_NAME_SYN\tFORMULA\tCOMP_NUM\n")


files = "*.pdb"

file_list = glob.glob(indir+"/"+files)

if file_list:
	file_list.sort()
	cnt = 0
	for filename in file_list:
		matchObj = re.match(r'.*/(.+)\.pdb',filename,re.S)
		pdbid = matchObj.group(1)
		#print "***"+pdbid
		###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
		###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
		###AS A CORRECTION, pdbid_actual is set to pdbid.
		#matchObj = re.match(r'.*/(....)(.*?)_?(.?)\.pdb',filename,re.S)
		#matchObj = re.match(r'(....)(.*?)_?(.?)',pdbid,re.S)
		#pdbid_actual = matchObj.group(1)
		pdbid_actual = pdbid
		#print "***"+matchObj.group(1)+" "+matchObj.group(2)+" "+matchObj.group(3)

		dsspFilename = dsspdir+"/"+pdbid+".dssp"
		print "Processing " + pdbid + " : " + filename + " ..."
		print "PDB ID: "+pdbid_actual

		mypdb = pdb3.Pdb3(filename)
		mypdb.setCoordData()

		coord = mypdb.pdbCoordData
		atomCoord = mypdb.atomCoordData
		missingResData = mypdb.missingResData
		missingAtomData = mypdb.missingAtomData
		modresData = mypdb.modresData
		hetData = mypdb.hetData
		hetnamData = mypdb.hetnamData
		seq = mypdb.seq


		mydssp = dssp.Dssp(dsspFilename)
		mydssp.setDsspData()

		dsspData = mydssp.dsspData
		dssp2pdbResnum = mydssp.dssp2pdbResnum

		asaFilename = naccessdir+"/"+pdbid+".asa"
		rsaFilename = naccessdir+"/"+pdbid+".rsa"
		asacFilename = naccessdir+"/"+pdbid+".asac"
		rsacFilename = naccessdir+"/"+pdbid+".rsac"

		mynaccess = naccess.Naccess(asaFilename,rsaFilename)
		mynaccess.setNaccessData()
		asaData = mynaccess.asaData
		rsaData = mynaccess.rsaData
		chainAsaData = mynaccess.chainData

		mynaccessc = naccess.Naccess(asacFilename,rsacFilename)
		mynaccessc.setNaccessData()
		asacData = mynaccessc.asaData
		rsacData = mynaccessc.rsaData
		chainAsacData = mynaccessc.chainData



		atomLines = []
		resLines = []
		chainTable = []

		for chain in coord.keys():

			ATOM_resCnt = 0
			HETATM_resCnt = 0
			ATOM_cnt = 0
			HETATM_cnt = 0

			for resnum in coord[chain].keys():

				benSymbol = "X"
				if pdbid+'_'+chain+'_'+resnum in resHash:
					benSymbol = resHash[pdbid+'_'+chain+'_'+resnum]

###WRITE RESIDUE TABLE
				resLine = ""
				#print dsspData[chain][resnum]['RES_NAME']
				resLine += pdbid_actual + "\t" + chain + "\t" + resnum + "\t" + coord[chain][resnum]['RES_NAME'] + "\t" + benSymbol + "\t"
###THIS IF CONDITION IS REQUIRED BECAUSE HETATM LINES ARE NOT CONSIDERED AS PARTS OF RESIDUES IN DSSP FILES,
###SO IT WILL GIVE ERROR AS THOSE RESIDUE NUMBERS WILL BE ABSENT IN dsspData.
				if resnum in dsspData[chain]:

					if dsspData[chain][resnum]['BP1'] != 0:
						resLine += dssp2pdbResnum[dsspData[chain][resnum]['BP1']] + "\t"
					else:
						resLine += "0\t"
					if dsspData[chain][resnum]['BP2'] != 0:
						resLine += dssp2pdbResnum[dsspData[chain][resnum]['BP2']] + "\t"
					else:
						resLine += "0\t"

					resLine += dsspData[chain][resnum]['SEC_STRUCT'] + "\t" + dsspData[chain][resnum]['SEC_STRUCT_INFO'] + "\t" + str(dsspData[chain][resnum]['PHI']) + "\t" + str(dsspData[chain][resnum]['PSI']) + "\t" + str(dsspData[chain][resnum]['TCO']) + "\t" + str(dsspData[chain][resnum]['KAPPA']) + "\t" + str(dsspData[chain][resnum]['ALPHA'])
				else:
					resLine += "0\t0\tNA\tNA\t999\t999\t999\t999\t999"

				if resnum in rsaData[chain].keys():
					resLine += "\t" + str(rsaData[chain][resnum]['ALL_ABS']) + "\t" + str(rsaData[chain][resnum]['ALL_REL']) + "\t" + str(rsaData[chain][resnum]['SC_ABS']) + "\t" + str(rsaData[chain][resnum]['SC_REL']) + "\t" + str(rsaData[chain][resnum]['MC_ABS']) + "\t" + str(rsaData[chain][resnum]['MC_REL']) + "\t" + str(rsaData[chain][resnum]['NP_ABS']) + "\t" + str(rsaData[chain][resnum]['NP_REL']) + "\t" + str(rsaData[chain][resnum]['P_ABS']) + "\t" + str(rsaData[chain][resnum]['P_REL'])
				else:
					resLine += "\t" + "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0"

				if resnum in rsacData[chain].keys():
					resLine += "\t" + str(rsacData[chain][resnum]['ALL_ABS']) + "\t" + str(rsacData[chain][resnum]['ALL_REL']) + "\t" + str(rsacData[chain][resnum]['SC_ABS']) + "\t" + str(rsacData[chain][resnum]['SC_REL']) + "\t" + str(rsacData[chain][resnum]['MC_ABS']) + "\t" + str(rsacData[chain][resnum]['MC_REL']) + "\t" + str(rsacData[chain][resnum]['NP_ABS']) + "\t" + str(rsacData[chain][resnum]['NP_REL']) + "\t" + str(rsacData[chain][resnum]['P_ABS']) + "\t" + str(rsacData[chain][resnum]['P_REL'])
				else:
					resLine += "\t" + "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t-1.0"

				resLine += "\n"
				resTableFile.write(resLine)
				#print resLine

				res_ATOM = 0
				res_HETATM = 0

				for atomname in coord[chain][resnum].keys():

###CHECK IF RESIDUE IS ATOM OR HETATM
					if atomname != 'RES_NAME':
						for alt_loc in coord[chain][resnum][atomname].keys():
							if coord[chain][resnum][atomname][alt_loc]['TAG'] == 'ATOM':
								res_ATOM = 1
							if coord[chain][resnum][atomname][alt_loc]['TAG'] == 'HETATM':
								res_HETATM = 1


						#if atomname != 'RES_NAME':
							atomInfo = coord[chain][resnum][atomname][alt_loc]

###WRITE ATOM TABLE
							atomLine = ""
							atomLine += pdbid_actual + "\t" + str(atomInfo['ATOM_NUM']) + "\t" + alt_loc + "\t" + atomInfo['TAG'] + "\t"
							atomLine += chain + "\t" + resnum + "\t" + atomname + "\t"
							atomLine += str(atomInfo['X']) + "\t" + str(atomInfo['Y']) + "\t" + str(atomInfo['Z']) + "\t"
							atomLine += str(atomInfo['OCP']) + "\t" + str(atomInfo['B_FACT']) + "\t" + atomInfo['ELEMENT'] + "\t" + atomInfo['CHARGE']

							if resnum in asaData[chain].keys() and atomname in asaData[chain][resnum].keys() and alt_loc in asaData[chain][resnum][atomname].keys():
								atomLine += "\t" + str(asaData[chain][resnum][atomname][alt_loc]['ASA'])
							else:
								atomLine += "\t" + "-1.0"

							if resnum in asacData[chain].keys() and atomname in asacData[chain][resnum].keys() and alt_loc in asacData[chain][resnum][atomname].keys():
								atomLine += "\t" + str(asacData[chain][resnum][atomname][alt_loc]['ASA'])
							else:
								atomLine += "\t" + "-1.0"

							atomLine += "\n"

							atomTableFile.write(atomLine)
							#print atomLine

###COUNT TOTAL NUMBER OF ATOMS AND HETATMS IN CHAIN
							if atomInfo['TAG'] == 'ATOM':
								ATOM_cnt += 1
							if atomInfo['TAG'] == 'HETATM':
								HETATM_cnt += 1

###COUNT TOTAL NUMBER OF RESIDUES WITH ATOM AND HETATM TAGS IN CHAIN
				if res_ATOM == 1:
					ATOM_resCnt += 1
				if res_HETATM == 1:
					HETATM_resCnt += 1


###WRITE CHAIN TABLE
			chainLine = ""
			chainLine += pdbid_actual + "\t" + chain + "\t"
			chainLine += str(ATOM_resCnt) + "\t" + str(HETATM_resCnt) + "\t" + str(ATOM_cnt) + "\t" + str(HETATM_cnt) + "\t"
			if chain in chainAsaData.keys():
				chainLine += str(chainAsaData[chain]['ALL']) + "\t" + str(chainAsaData[chain]['SC']) + "\t" + str(chainAsaData[chain]['MC']) + "\t" + str(chainAsaData[chain]['NP']) + "\t" + str(chainAsaData[chain]['P']) + "\t"
				chainLine += str(chainAsacData[chain]['ALL']) + "\t" + str(chainAsacData[chain]['SC']) + "\t" + str(chainAsacData[chain]['MC']) + "\t" + str(chainAsacData[chain]['NP']) + "\t" + str(chainAsacData[chain]['P']) + "\t"
			else:
				chainLine += "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t"
				chainLine += "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t"
			chainLine += ",".join(seq[chain]) + "\t" + str(len(seq[chain])) + "\n"
			chainTableFile.write(chainLine)
			#print chainLine


###WRITE MODRES TABLE
		for chain in modresData.keys():
			if chain in coord.keys():
				for resNum in modresData[chain].keys():
					modresTableFile.write(pdbid_actual + "\t" + chain + "\t" + resNum + "\t" + modresData[chain][resNum]['RES_NAME'] + "\t" + modresData[chain][resNum]['STD_RES_NAME'] + "\t" + modresData[chain][resNum]['COMMENT'] + "\n")

###WRITE HET TABLE
		for chain in hetData.keys():
			for resNum in hetData[chain].keys():
				hetTableFile.write(pdbid_actual + "\t" + chain + "\t" + resNum + "\t" + hetData[chain][resNum]['RES_NAME']  + "\t" + str(hetData[chain][resNum]['NUM_HETATM']) + "\t" + hetData[chain][resNum]['DESC'] + "\n")

###WRITE hetinfo TABLE
		for resName in hetnamData.keys():
			hetinfoTableFile.write(pdbid_actual + "\t" + resName + "\t" + hetnamData[resName]['CHEM_NAME'] + "\t" + hetnamData[resName]['CHEM_NAME_SYN'] + "\t" + hetnamData[resName]['FORMULA'] + "\t" + hetnamData[resName]['COMP_NUM'] + "\n")

###WRITE MISSING RESIDUE TABLE
		for chain in missingResData.keys():
			for resNum in missingResData[chain].keys():
#				if chain not in coord.keys():
					###WRITE CHAIN TABLE ENTRY FOR MISSING CHAIN
#					chainLine = ""
#					chainLine += pdbid_actual + "\t" + chain + "\t"
#					chainLine += "-1\t-1\t-1\t-1\t"
#					chainLine += "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t"
#					chainLine += "-1.0\t-1.0\t-1.0\t-1.0\t-1.0\t"
#					chainLine += " \t-1\n"
#					chainTableFile.write(chainLine)
				if chain in coord.keys():
					missingResTableFile.write(pdbid_actual + "\t" + chain + "\t" + resNum + "\t" + missingResData[chain][resNum]['RES_NAME'] + "\n")

###WRITE MISSING ATOM TABLE
		for chain in missingAtomData.keys():
			for resNum in missingAtomData[chain].keys():
				for atomName in missingAtomData[chain][resNum].keys():
					if chain in coord.keys():
						missingAtomTableFile.write(pdbid_actual + "\t" + chain + "\t" + resNum + "\t" + missingAtomData[chain][resNum][atomName]['RES_NAME'] + "\t" + atomName + "\n")


###CLEAR DATA
		mypdb.pdbCoordData.clear()
		mypdb.atomCoordData.clear()
		mypdb.missingResData.clear()
		mypdb.missingAtomData.clear()
		mydssp.dsspData.clear()
		mynaccess.asaData.clear()
		mynaccess.rsaData.clear()
		mynaccess.chainData.clear()
		mynaccessc.asaData.clear()
		mynaccessc.rsaData.clear()
		mynaccessc.chainData.clear()

		cnt += 1
		print "#" + str(cnt) + "\nDONE\n"



atomTableFile.close()
resTableFile.close()
chainTableFile.close()
missingResTableFile.close()
missingAtomTableFile.close()
modresTableFile.close()
hetTableFile.close()
hetinfoTableFile.close()

