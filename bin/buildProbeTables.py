import pdb3
import glob
import re
from collections import defaultdict
import sys

indir = sys.argv[1]+"/pdb"

probedir = sys.argv[1]+"/pdbProbe"

tablesOutDir = sys.argv[2]

probeTable = "probeTable"

files = "*.pdb"

file_list = glob.glob(indir+"/"+files)

probeTableFile = open(tablesOutDir+"/"+probeTable,'w')

#probeTableFile.write("PDB_ID\tCHAIN1\tRESNAME1\tRESNUM1\tATOM1_NAME\tATOM1_NUM\tCHAIN2\tRESNAME2\tRESNUM2\tATOM2_NAME\tATOM2_NUM\tTYPE\tMINGAP\tGAP\tSCORE\n")
probeTableFile.write("PDB_ID\tPROBE_ID\tCHAIN1\tRES_NUM1\tATOM_NUM1\tALT_LOC1\tCHAIN2\tRES_NUM2\tATOM_NUM2\tALT_LOC2\tTYPE\tMINGAP\tGAP\tSCORE\n")


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

		probeFilename = probedir+"/"+pdbid+".probe"
		print "Processing " + pdbid + " : " + probeFilename + " ..."
		print "PDB ID: "+pdbid_actual

		mypdb = pdb3.Pdb3(filename)
		mypdb.setCoordData()

		coord = mypdb.pdbCoordData
		#atomCoord = mypdb.atomCoordData
		#missingResData = mypdb.missingResData
		#missingAtomData = mypdb.missingAtomData
		#modresData = mypdb.modresData
		#hetData = mypdb.hetData
		#hetnamData = mypdb.hetnamData


		probefile = open(probeFilename,'r')
		lines =  probefile.readlines()

#:1->1:bo: B  63 PHE  HD1 : B 129AARG HH21 :-0.853:-0.840:23.125:-17.292:-16.288:0.420:-0.2625:C:N:23.412:-17.584:-16.192:48.87:62.67		
#:1->1:bo: A  49 THR  CG2 : A  43 LEU HD21A:-0.604:-0.592:11.207:-9.378:55.208:0.296:-0.1850:C:C:11.040:-9.390:55.452:11.07:8.92
		probeId = 1
		for line in lines:
			#print line
			matchObj = re.match(r'.*?\:.+?\:(.+?)\:(.+?)\:(.+?)\:(.+?)\:(.+?)\:.+?\:.+?\:.+?\:.+?\:(.+?)\:.*',line,re.S)

			#print matchObj.group(1)

			TYPE = matchObj.group(1)
			ATOM1 = matchObj.group(2)
			ATOM2 = matchObj.group(3)
			MINGAP = float(matchObj.group(4))
			GAP = float(matchObj.group(5))
			SCORE = float(matchObj.group(6))

#: B 129AARG HH21 :
#: A  43 LEU HD21A:
			atom1Match = re.match(r'(..)(.....)(...)(.....)(.)',ATOM1,re.S)
			CHAIN1 = atom1Match.group(1).strip()
			RES_NUM1 = atom1Match.group(2).strip()
			RES_NAME1 = atom1Match.group(3).strip()
			ATOM_NAME1 = atom1Match.group(4).strip()
			ALT_LOC1 = atom1Match.group(5).strip()
			if ALT_LOC1 == '' or ALT_LOC1 == 'A':
				ALT_LOC1 = ' '
			if atom1Match.group(4).strip().endswith("?"):
				ATOM_NUM1 = -1
			else:
				ATOM_NUM1 = coord[CHAIN1][RES_NUM1][ATOM_NAME1][ALT_LOC1]['ATOM_NUM']

			atom2Match = re.match(r'(..)(.....)(...)(.....)(.)',ATOM2,re.S)
			CHAIN2 = atom2Match.group(1).strip()
			RES_NUM2 = atom2Match.group(2).strip()
			RES_NAME2 = atom2Match.group(3).strip()
			ATOM_NAME2 = atom2Match.group(4).strip()
			ALT_LOC2 = atom2Match.group(5)
			if ALT_LOC2 == '' or ALT_LOC2 == 'A':
				ALT_LOC2 = ' '
			if atom2Match.group(4).strip().endswith("?"):
				ATOM_NUM2 = -1
			else:
				ATOM_NUM2 = coord[CHAIN2][RES_NUM2][ATOM_NAME2][ALT_LOC2]['ATOM_NUM']

			if ALT_LOC1 == ' ' and ALT_LOC2 == ' ':
				probeTableFile.write(pdbid_actual + "\t" + str(probeId) + "\t" + CHAIN1 + "\t" + RES_NUM1 + "\t" + str(ATOM_NUM1) + "\t" + ALT_LOC1 + "\t" + CHAIN2 + "\t" + RES_NUM2 + "\t" + str(ATOM_NUM2) + "\t" + ALT_LOC2 + "\t" + TYPE + "\t" + str(MINGAP) + "\t" + str(GAP) + "\t" + str(SCORE) + "\n")
				probeId += 1


		cnt += 1
		print "#" + str(cnt) + "\nDONE\n"


probeTableFile.close()

