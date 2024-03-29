import pdb3
from collections import defaultdict
import math
import glob
import re
import sys

###SET SOME GLOBAL VARIABLES###

###THIS IS THE DISTANCE CUTOFF TO GET COVALENTLY BONDED HYDROGENS FOR ANY NON-HYDROGEN ATOM 'X'
xhCutoffDist = 1.11

###THIS IS THE DISTANCE CUTOFF FOR TWO INTERACTING RINGS. IT IS THE DISTANCE BETWEEN THE CENTROIDS OF THE RINGS.
cenCenDistCutoff = 10.0
###THIS CUTOFF DISTANCE IS DISTANCE BETWEEN ANY TWO ATOMS OF THE RINGS
pipiDistCutoff = 6.0

###THIS DEFINITION IS TAKEN FROM METHOD USED FOR RING SERVER.
cationPiCutoffDist = 7.0
###30 => FROM 0 TO 30
###60 => FROM 30 TO 60
###90 => FROM 60 TO 90
cationPiAngleCutoff = 60.0

cationPiPlanarAngleCutoff =\
{
	'PLANAR':     {'MIN':0.0,  'MAX': 30.0},
	'OBLIQUE':    {'MIN':30.0, 'MAX': 60.0},
	'ORTHOGONAL': {'MIN':60.0, 'MAX': 90.0},
}

cationDef =\
{
	'LYS' : ['NZ'],
	'ARG' : ['CZ'],
	'HIS' : ['ND1','CE1','NE2']
}

###FOLLOWING HASH DEFINES THE RING ATOMS OF AROMATIC RESIDUES
piRingDef =\
{
	'PHE' : ['CG','CD1','CD2','CE1','CE2','CZ'],
	'TYR' : ['CG','CD1','CD2','CE1','CE2','CZ'],
	'TRP' : ['CD2','CE2','CE3','CH2','CZ2','CZ3','CG','CD1','NE1',],
	'HIS' : ['CG','ND1','CD2','CE1','NE2']
}

###ATOMIC MASSES
mass = {'':12.011, 'C':12.011, 'N':14.007, 'O':15.999, 'S':32.066, 'H':1.008, 'Se':78.960, 'P':30.974}


#print coord['A'][1]['RES_NAME']
#print coord['A'][1]['O']['A']['Y']
#print coord['A'][1]['O']['A']['Z']



###FOLLOWING HASH DEFINES X-H-PI INTERACTION CUTOFF PARAMETERS.
###THEY VARY FOR DIFFERENT ATOMS OF DIFFERENT RESIDUES.
###999.0 AND -999.0 ARE WRITTEN BECAUSE THE CORRESPONDING PARAMETERS DO NOT HAVE LIMITS.
###REF: "NCI: a server to identify non-canonical interactions in protein structures, by M. Madan Babu"
xhpiInteractionThreshold =\
{
	'ARG' : {
						'NE'   :  {'XPIM' : 4.0, 'HPIM' : 3.8, 'XHPIM' : 10.0, 'XPIMPIN' : 30.0},
						'NH1'  :  {'XPIM' : 4.0, 'HPIM' : 3.8, 'XHPIM' : 10.0, 'XPIMPIN' : 30.0},
						'NH2'  :  {'XPIM' : 4.0, 'HPIM' : 3.8, 'XHPIM' : 10.0, 'XPIMPIN' : 30.0}
					},
	'LYS' : {
						'NZ'   :  {'XPIM' : 4.0, 'HPIM' : 3.8, 'XHPIM' : 10.0, 'XPIMPIN' : 30.0}
					},
	'CYS' : {
						'SG'   :  {'XPIM' : 4.0, 'HPIM' : 999.0, 'XHPIM' : -999.0,'XPIMPIN' : 30.0} 
					},
	'SER' : {
						'OG'   :  {'XPIM' : 3.8, 'HPIM' : 999.0, 'XHPIM' : -999.0,'XPIMPIN' : 30.0}
					},
	'THR' : {
						'OG1'  :  {'XPIM' : 3.8, 'HPIM' : 999.0, 'XHPIM' : -999.0,'XPIMPIN' : 30.0}
					},
	'TYR' : {
						'OH'   :  {'XPIM' : 3.8, 'HPIM' : 999.0, 'XHPIM' : -999.0,'XPIMPIN' : 30.0}
					},
	'PRO' : {
						'CD'   :  {'XPIM' : 4.3, 'HPIM' : 3.8, 'XHPIM' : 120.0,'XPIMPIN' : 30.0}
					},
	'*'   : {
						'N'    :  {'XPIM' : 4.3, 'HPIM' : 3.5, 'XHPIM' : 120.0, 'XPIMPIN' : 30.0},
						'CA'   :  {'XPIM' : 4.3, 'HPIM' : 3.8, 'XHPIM' : 120.0, 'XPIMPIN' : 30.0},
						'*'    :  {'XPIM' : 4.3, 'HPIM' : 3.8, 'XHPIM' : 120.0, 'XPIMPIN' : 30.0},
				  }
}

###NOTE: FIRST '*' MEANS 'ANY RESIDUE'.
###      SECOND '*' SHOULD MEAN ANY ATOM, BUT HERE THE HASH IS FOR CH-O INTERACTIONS, SO '*' MEANS ANY CARBON.
###      USER SHOULD TAKE CARE THAT THESE THRESHOLDS ARE USED ONLY FOR CARBON ATOMS.
chOInteractionThreshold =\
{
	'*'   : {
						'*'    :	{'CO' : 3.8, 'HO' : 3.3, 'CHO' : 120.0, 'HOC' : 90.0}
					}
}

#print mcXhPiThreshold['N']['HPIM']
#print scXhPiThreshold['CYS']['SG']['XPIM']


######################################################################
######################################################################

def infinite_defaultdict():
	return defaultdict(infinite_defaultdict)
###END infinite_deraultdict()###


def findPiPiInteractions(pdbid):

	#pipiOut.write("PI_CH_NAME_1\tPI_RES_NUM_1\tPI_RES_NAME_1\tPI_CH_NAME_2\tPI_RES_NUM_2\tPI_RES_NAME_2\tPI-CEN_PI-CEN_DIST\tPIN_PIN_ANGLE\tCLOSEST\tFARTHEST\tPIM_1_X\tPIM_1_Y\tPIM_1_Z\tPIM_2_X\tPIM_2_Y\tPIM_2_Z\n")

	pipiLines = []
	ringIds = ringHash.keys()
	cnt1 = 0
	while cnt1 < len(ringIds):
		cnt2 = cnt1 + 1
		while cnt2 < len(ringIds)-1:
			ringId1 = ringIds[cnt1]
			ringId2 = ringIds[cnt2]

			cenCenDist = dist([ringHash[ringId1]['CENTROID']['X'],ringHash[ringId1]['CENTROID']['Y'],ringHash[ringId1]['CENTROID']['Z']],[ringHash[ringId2]['CENTROID']['X'],ringHash[ringId2]['CENTROID']['Y'],ringHash[ringId2]['CENTROID']['Z']])
			pin1 = [ringHash[ringId1]['PLANE'][0],ringHash[ringId1]['PLANE'][1],ringHash[ringId1]['PLANE'][2]]
			pin2 = [ringHash[ringId2]['PLANE'][0],ringHash[ringId2]['PLANE'][1],ringHash[ringId2]['PLANE'][2]]
			pinPinAngle = math.degrees(angle2Vectors(pin1,pin2))
			#pinPinAngle = angle2Vectors(pin1,pin2)

			#print "Calculating interaction between rings: ",cenCenDist,ringId1,ringId2,ringHash[ringId1]['CHAIN'],ringHash[ringId1]['RES_NUM'],ringHash[ringId1]['RES_NAME'],ringHash[ringId2]['CHAIN'],ringHash[ringId2]['RES_NUM'],ringHash[ringId2]['RES_NAME']
						
			pipiLine = ""

###FIND CLOSEST AND FARTHEST ATOMS OF TWO RINGS.
###VECTORS (CLOSE1,FAR1) AND (CLOSE2,FAR2) WILL BE USED TO CHECK WHETHER RINGS MAKE ACUTE OR OBTUSE ANGLE WITH EACHOTHER.
			i = 0
			farD = -1
			closeD = 99999
			while i < len(ringHash[ringId1]['ATOM_NUMS']):
				j = i+1
				while j < len(ringHash[ringId2]['ATOM_NUMS']):
					atom1 = ringHash[ringId1]['ATOM_NUMS'][i]
					atom2 = ringHash[ringId2]['ATOM_NUMS'][j]
					d = dist([atomCoord[atom1]['X'],atomCoord[atom1]['Y'],atomCoord[atom1]['Z']],[atomCoord[atom2]['X'],atomCoord[atom2]['Y'],atomCoord[atom2]['Z']])
					if d > farD:
						farAtom1 = atom1
						farAtom2 = atom2
						farD = d

					if d < closeD:
						closeAtom1 = atom1
						closeAtom2 = atom2
						closeD = d

					j += 1
				i += 1

###END WHILE

			"""
###TRANSLATE RING2 SUCH THAT THE CLOSEST ATOMS OF RING1 AND RING2 COINCIDE.
###THIS HAS TO BE DONE SO THAT BIAS BECAUSE OF DISTANCE BETWEEN THE RINGS WONT BE THERE.
			xtrans = atomCoord[closeAtom1]['X'] - atomCoord[closeAtom2]['X']
			ytrans = atomCoord[closeAtom1]['Y'] - atomCoord[closeAtom2]['Y']
			ztrans = atomCoord[closeAtom1]['Z'] - atomCoord[closeAtom2]['Z']

###CALCULATE DISTANCES WHEN RING2 IS TRANSLATED BY xtrans, ytrans AND ztrans
			i = 0
			dists = []
#			farD = -1
#			closeD = 99999
			while i < len(ringHash[ringId1]['ATOM_NUMS']):
				j = i+1
				while j < len(ringHash[ringId2]['ATOM_NUMS']):
					atom1 = ringHash[ringId1]['ATOM_NUMS'][i]
					atom2 = ringHash[ringId2]['ATOM_NUMS'][j]
					d = dist([atomCoord[atom1]['X'],atomCoord[atom1]['Y'],atomCoord[atom1]['Z']],[atomCoord[atom2]['X']+xtrans,atomCoord[atom2]['Y']+ytrans,atomCoord[atom2]['Z']+ztrans])
					dists.append(d)

					j += 1
				i += 1

###CALCULATE STANDARD DEVIATION OF ALL TO ALL ATOM DISTANCES IN TWO RINGS.
###THIS SHOULD BE SMALLEST FOR PARALLEL RINGS, SLIGHTLY LARGER FOR RINGS WITH ACUTE ANGLE AND LARGEST FOR RINGS WITH OBTUSE ANGLE.
			avgDist = sum(dists)/len(dists)
			stdv =	math.sqrt(sum(map(lambda x: (x-avgDist)**2,dists))/len(dists))

###THIS WAS WRITTEN TO CHANGE ANGLE BASED ON WHETHER RINGS FACE EACH OTHER OR NOT. BUT THIS DID NOT WORK.
#			if (abs(closeD-farD) > 3 and pinPinAngle < 3.142/2) or (abs(closeD-farD) <= 3 and pinPinAngle >= 3.142/2):
#				pinPinAngle = 3.142 - pinPinAngle

			"""

			if closeD <= pipiDistCutoff:
				pipiLine += pdbid + "\t"
				pipiLine += str(ringId1) + "\t"
				pipiLine += str(ringId2) + "\t"
				#pipiLine += ringHash[ringId1]['CHAIN'] + "\t" + ringHash[ringId1]['RES_NUM'] + "\t"
				#pipiLine += ringHash[ringId2]['CHAIN'] + "\t" + ringHash[ringId2]['RES_NUM'] + "\t"
				pipiLine += str(cenCenDist) + "\t" + str(pinPinAngle) + "\t" + str(closeAtom1) + "\t" + str(closeAtom2) + "\t" + str(closeD) + "\t" + ringHash[ringId1]['ALT_LOC'] + "\t" + str(farAtom1) + "\t" + str(farAtom2) + "\t" + str(farD) + "\t" + ringHash[ringId2]['ALT_LOC'] + "\n"

				pipiLines.append(pipiLine)

			cnt2 += 1
		cnt1 += 1

	return(pipiLines)
###END FUNCTION findPiPiInteractions()###


def stdev(values):
	avg = sum(values)/len(values)
	stdev =	math.sqrt(sum(map(lambda x: (x-avg)**2,values))/len(values))
	return(stdev)
###END FUNCTION stdev(values)###


def findChOInteractions(pdbid):
	choLines = []

	for atomNum in atomCoord.keys():
		if atomCoord[atomNum]['TAG'] == 'ATOM' and atomCoord[atomNum]['ATOM_NAME'] == 'O':
			for xhId in xhHash.keys():
				if xhHash[xhId]['X_ATOM']['ELEMENT'] == 'C':

					resName = '*'
					atomName = '*'

					if     abs(xhHash[xhId]['X_ATOM']['X']-atomCoord[atomNum]['X']) <= chOInteractionThreshold[resName][atomName]['CO']\
						 and abs(xhHash[xhId]['X_ATOM']['Y']-atomCoord[atomNum]['Y']) <= chOInteractionThreshold[resName][atomName]['CO']\
						 and abs(xhHash[xhId]['X_ATOM']['Z']-atomCoord[atomNum]['Z']) <= chOInteractionThreshold[resName][atomName]['CO']\
						 and abs(xhHash[xhId]['H_ATOM']['X']-atomCoord[atomNum]['X']) <= chOInteractionThreshold[resName][atomName]['HO']\
						 and abs(xhHash[xhId]['H_ATOM']['Y']-atomCoord[atomNum]['Y']) <= chOInteractionThreshold[resName][atomName]['HO']\
						 and abs(xhHash[xhId]['H_ATOM']['Z']-atomCoord[atomNum]['Z']) <= chOInteractionThreshold[resName][atomName]['HO']:

						co = dist([ xhHash[xhId]['X_ATOM']['X'],xhHash[xhId]['X_ATOM']['Y'],xhHash[xhId]['X_ATOM']['Z'] ],[ atomCoord[atomNum]['X'],atomCoord[atomNum]['Y'],atomCoord[atomNum]['Z'] ])
						if co <= chOInteractionThreshold[resName][atomName]['CO']:
							ho = dist([ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ],[ atomCoord[atomNum]['X'],atomCoord[atomNum]['Y'],atomCoord[atomNum]['Z'] ])
							if ho <= chOInteractionThreshold[resName][atomName]['HO']:
								v1 = vector([ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ],[ xhHash[xhId]['X_ATOM']['X'],xhHash[xhId]['X_ATOM']['Y'],xhHash[xhId]['X_ATOM']['Z'] ])
								v2 = vector([ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ],[ atomCoord[atomNum]['X'],atomCoord[atomNum]['Y'],atomCoord[atomNum]['Z'] ])
								cho = math.degrees(angle2Vectors(v1,v2))
								if cho >= chOInteractionThreshold[resName][atomName]['CHO']:
									oChain = atomCoord[atomNum]['CHAIN']
									oResNum = atomCoord[atomNum]['RES_NUM']
									oAltLoc = atomCoord[atomNum]['ALT_LOC']
									if 'C' in coord[oChain][oResNum].keys():
										#print oChain + "*" + oResNum + "*" + oAltLoc + "*"
										#print str(atomCoord[atomNum]['X']) + "\t" + str(atomCoord[atomNum]['Y']) + "\t" + str(atomCoord[atomNum]['Z']) + "\t" + str(coord[oChain][oResNum]['C'][oAltLoc]['X']) + "\t" + str(coord[oChain][oResNum]['C'][oAltLoc]['Y']) + "\t" + str(coord[oChain][oResNum]['C'][oAltLoc]['Z'])
										#print oChain + "\t" + oResNum + "\t" + oAltLoc + "\t" + str(coord[oChain][oResNum]['C'][oAltLoc])
										#cAtomNum = coord[chain][resNum]['C']['A']['ATOM_NUM']
										#print pdbid + " " + chain + " " + resNum + " " + coord[chain][resNum]['C']['A']['X'] + " " + coord[chain][resNum]['C']['A']['Y'] + " " + coord[chain][resNum]['C']['A']['Z']
										v3 = vector([ atomCoord[atomNum]['X'],atomCoord[atomNum]['Y'],atomCoord[atomNum]['Z'] ],[ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ])
										v4 = vector([ atomCoord[atomNum]['X'],atomCoord[atomNum]['Y'],atomCoord[atomNum]['Z'] ],[ coord[oChain][oResNum]['C'][oAltLoc]['X'],coord[oChain][oResNum]['C'][oAltLoc]['Y'],coord[oChain][oResNum]['C'][oAltLoc]['Z'] ])
										hoc = math.degrees(angle2Vectors(v3,v4))
										if hoc >= chOInteractionThreshold[resName][atomName]['HOC']:
											#print xhHash[xhId]['X_ATOM']['ATOM_NAME'],atomCoord[atomNum]['ATOM_NAME'],co,ho,cho,hoc
											choLines.append(pdbid+"\t"+str(xhId)+"\t"+oChain+"\t"+oResNum+"\t"+str(coord[oChain][oResNum]['O'][oAltLoc]['ATOM_NUM'])+"\t"+oAltLoc+"\t"+str(co)+"\t"+str(ho)+"\t"+str(cho)+"\t"+str(hoc)+"\n")
	return(choLines)
###END FUNCTION findChOInderactions(pdbid)###


def findCationPiInteractions(pdbid):
	cationPiLines = []
	for cationId in cationHash.keys():
		for ringId in ringHash.keys():
###THIS IF CONDITION IS REQUIRED BECAUSE HISTIDINE IS CATION AS WELL AS PI RING RESIDUE. THUS THIS WILL AVOID CONSIDERING SAME RESIDUE BOTH AS RING AND CATION.
			if not(ringHash[ringId]['CHAIN'] == cationHash[cationId]['CHAIN'] and ringHash[ringId]['RES_NUM'] == cationHash[cationId]['RES_NUM']):
				cationPiLine = ""
				if     abs(ringHash[ringId]['CENTROID']['X']-cationHash[cationId]['CM']['X']) <= cationPiCutoffDist\
					 and abs(ringHash[ringId]['CENTROID']['Y']-cationHash[cationId]['CM']['Y']) <= cationPiCutoffDist\
					 and abs(ringHash[ringId]['CENTROID']['Z']-cationHash[cationId]['CM']['Z']) <= cationPiCutoffDist:
					catPim = dist([ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ],[ cationHash[cationId]['CM']['X'],cationHash[cationId]['CM']['Y'],cationHash[cationId]['CM']['Z'] ])
					if catPim <= cationPiCutoffDist:
						v1 = vector([ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ],[ cationHash[cationId]['CM']['X'],cationHash[cationId]['CM']['Y'],cationHash[cationId]['CM']['Z'] ])
						v2 = [ ringHash[ringId]['PLANE'][0],ringHash[ringId]['PLANE'][1],ringHash[ringId]['PLANE'][2] ]
						catPimPin = math.degrees(angle2Vectors(v1,v2))
						###THE ANGLE catPimPin IS NOT WRITTEN AS ACUTE ANGLE IN THE FILE BECAUSE, IT GIVES INFORMATION ABOUT THE ORIENTATION OF THE RING WITH RESPECT TO THE MAIN CHAIN CA.
						###RING NORMAL IS ALWAYS CALCULATED POINTING TO THE DIRECTION SUCH THAT CA-PIM-PIN <= 90.
						###SO THE OBTUSENESS OR ACUTENESS OF catPimPin TELLS ON WHICH SIDE OF THE RING IT LIES.
						if catPimPin <= cationPiAngleCutoff or catPimPin >= 180-cationPiAngleCutoff:
							cationPiLines.append(pdbid + "\t" + str(cationId) + "\t" + str(ringId) + "\t" + str(catPim) + "\t" + str(catPimPin) + "\n")

	return(cationPiLines)

#END FUNCTION findCationPiInteractions()###


def findXhPiInteractions(pdbid):

	xhpiLines = []

	for xhId in xhHash.keys():
		for ringId in ringHash.keys():
			xhpiLine = ""
			if     abs(ringHash[ringId]['CENTROID']['X']-xhHash[xhId]['X_ATOM']['X']) <= 4.3\
				 and abs(ringHash[ringId]['CENTROID']['Y']-xhHash[xhId]['X_ATOM']['Y']) <= 4.3\
				 and abs(ringHash[ringId]['CENTROID']['Z']-xhHash[xhId]['X_ATOM']['Z']) <= 4.3:
				if xhHash[xhId]['RES_NAME'] in xhpiInteractionThreshold and xhHash[xhId]['X_ATOM']['ATOM_NAME'] in xhpiInteractionThreshold[xhHash[xhId]['RES_NAME']]:
					resName = xhHash[xhId]['RES_NAME']
					atomName = xhHash[xhId]['X_ATOM']['ATOM_NAME']
				elif xhHash[xhId]['X_ATOM']['ATOM_NAME'] in xhpiInteractionThreshold['*']:
					resName = '*'
					atomName = xhHash[xhId]['X_ATOM']['ATOM_NAME']
				else:
					resName = '*'
					atomName = '*'

				#print resName,atomName
				xPim = dist([ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ],[ xhHash[xhId]['X_ATOM']['X'],xhHash[xhId]['X_ATOM']['Y'],xhHash[xhId]['X_ATOM']['Z'] ])
				###IF CONDITION FOR xPim
				if xPim <= xhpiInteractionThreshold[resName][atomName]['XPIM']:
					hPim = dist([ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ],[ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ])
					###IF CONDITION FOR hPim
					if hPim <= xhpiInteractionThreshold[resName][atomName]['HPIM']:
						v1 = vector([ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ],[ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ])
						v2 = vector([ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ],[ xhHash[xhId]['X_ATOM']['X'],xhHash[xhId]['X_ATOM']['Y'],xhHash[xhId]['X_ATOM']['Z'] ])
						xhpim = math.degrees(angle2Vectors(v1,v2))
						###IF CONDITION FOR xhpim
						if xhpim >= xhpiInteractionThreshold[resName][atomName]['XHPIM']:
							v1 = vector([ ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z'] ],[ xhHash[xhId]['H_ATOM']['X'],xhHash[xhId]['H_ATOM']['Y'],xhHash[xhId]['H_ATOM']['Z'] ])
							v2 = [ ringHash[ringId]['PLANE'][0],ringHash[ringId]['PLANE'][1],ringHash[ringId]['PLANE'][2] ]
							xPimPin = math.degrees(angle2Vectors(v1,v2))
							#print ">>",resName,atomName,xPimPin,xhpiInteractionThreshold[resName][atomName]['XPIMPIN']
							###IF CONDITION FOR xPimPin
							###NOTE: IF xPimPin IS WITHIN 150 AND 180 THEN IT MEANS THAT CA ATOM OF PI-RESIDUE IS ON THE OTHER SIDE OF THE RING AS THAT OF X-H DONAR.
							###WHILE USING THIS VALUE, CONVERT IT TO ACUTE ANGLE: 180-xPimPin TEMPORARILY.
							###THE ANGLE xPimPin IS NOT WRITTEN AS ACUTE ANGLE IN THE FILE BECAUSE, IT GIVES INFORMATION ABOUT THE ORIENTATION OF THE RING WITH RESPECT TO THE MAIN CHAIN CA.
							###RING NORMAL IS ALWAYS CALCULATED POINTING TO THE DIRECTION SUCH THAT CA-PIM-PIN <= 90.
							###SO THE OBTUSENESS OR ACUTENESS OF xPimPin TELLS ON WHICH SIDE OF THE RING IT LIES.
							if xPimPin <= xhpiInteractionThreshold[resName][atomName]['XPIMPIN'] or xPimPin >= 180-xhpiInteractionThreshold[resName][atomName]['XPIMPIN']:
								xhpiLine += pdbid + "\t"
								xhpiLine += str(xhId) + "\t"
								xhpiLine += str(ringId) + "\t"
								#xhpiLine += xhHash[xhId]['CHAIN'] + "\t" + str(xhHash[xhId]['RES_NUM']) + "\t"
								#xhpiLine += str(xhHash[xhId]['X_ATOM']['ATOM_NUM']) + "\t"
								#xhpiLine += str(xhHash[xhId]['H_ATOM']['ATOM_NUM']) + "\t"
								#xhpiLine += ringHash[ringId]['CHAIN'] + "\t" + str(ringHash[ringId]['RES_NUM']) + "\t"
								xhpiLine += str(xPim) + "\t" + str(hPim) + "\t" + str(xhpim) + "\t" + str(xPimPin) + "\n"

								xhpiLines.append(xhpiLine)

	return(xhpiLines)

###END FUNCTION findXhPiInteractions()###	


def calcCenterOfMass(points,weights):
	cen = [0.0,0.0,0.0]

	j = 0
	for point in points:
		i = 0
		for coord in point:
			cen[i] += coord * weights[j]
			i += 1
	j += 1

#	print len(points)
	if len(points) > 0:
		i = 0
		for x in cen:
#			print cen[i]
			cen[i] /= sum(weights)
			i += 1

	return cen
###END FUNCTION calcCenterOfMass()###


def calcCentroid(points):
	cen = [0.0,0.0,0.0]

	for point in points:
		i = 0
		for coord in point:
			cen[i] += coord
			i += 1

#	print len(points)
	if len(points) > 0:
		i = 0
		for x in cen:
#			print cen[i]
			cen[i] /= len(points)
			i += 1

	return cen
###END FUNCTION calcCentroid()###


def gaussElimination(mat):
#	print "\n===BEGIN GAUSS ELEMINATION===\n\n"
#	print "Augmented Matrix:\n"

	i = 0
	while i < len(mat)-1:
		j = i+1
		while j < len(mat):
			#print "pivot: ",i,i," | col: ",i," | rows: ",i,j
			if mat[j][i] != 0:
				if abs(mat[i][i]) < abs(mat[j][i]):
					#swap rows i and j
					temp = mat[i]
					mat[i] =mat[j]
					mat[j] = temp
				#END IF

#				print mat[0]
#				print mat[1]
#				print mat[2]

				#make mat[j][i] zero
				multFactor = mat[j][i]/mat[i][i]
#				print "#",multFactor
				m = 0
				#print "i j m  : [j][m] -= [i][m] * multFactor"
				while m <= len(mat):
#					print i,j,m," : ",mat[j][m]," -= ",mat[i][m]," * ",multFactor
					mat[j][m] -= mat[i][m] * multFactor
					m += 1
				#END FOR

			j += 1
		#END FOR

		i += 1
	#END FOR

#	print "\n---Triangularized matrix---"
#	for row in mat:
#		for col in row:
#			print col,
#		print ""
#	print "-----------------------\n"
	#calculation of solution

	soln = []
	for t in mat:
		soln.append(0)

	i = len(mat) - 1
	while i >= 0:
		val = 0
		j = len(mat) - 1
		while j >= 0:
			if i != j:
				val += mat[i][j] * soln[j]

			#print "mat ",i,i," = ",mat[i][i]
			soln[i] = (mat[i][len(mat)] - val)/mat[i][i]

			j -= 1
		#END WHILE

		i -= 1
	#END WHILE
	#print "\n===END GAUSS ELEMINATION===\n\n"

	return soln
###END FUNCTION gaussElimination(mat)###


def getLstSqrPlane(points):
	#calculate least square fitting plane through the points
	#with gauss elemination(passes through centroid)
	
	#print "\n===BEGIN CALCULATION OF LEAST SQUARE PLANE===\n\n"
	#print centroid of given points
	cen = calcCentroid(points)
	#print "Centroid: ",cen
	
	sumX=0
	sumY=0
	sumZ=0
	sumXsqr=0
	sumYsqr=0
	sumXY=0
	sumYZ=0
	sumXZ=0

	for point in points:
		sumX += point[0]
		sumY += point[1]
		sumZ += point[2]

		sumXsqr += point[0]**2
		sumYsqr += point[1]**2

		sumXY += point[0]*point[1]
		sumYZ += point[1]*point[2]
		sumXZ += point[0]*point[2]
	#FOR

 	l = len(points)
	augMat = [ [l,sumX,sumY,sumZ], [sumX,sumXsqr,sumXY,sumXZ], [sumY,sumXY,sumYsqr,sumYZ] ]
	
#	print "*",l,sumX,sumY,sumZ
#	print "*",sumX,sumXsqr,sumXY,sumXZ
#	print "*",sumY,sumXY,sumYsqr,sumYZ
	
	abc = gaussElimination(augMat)
	planeCoeff = [ abc[1],abc[2],-1,abc[0] ]
	#print "\nplane(lsqr) : f(x,y) = ",abc[0]," + (",abc[1],")*x + (",abc[2],")*y\n"
	#print "\n===END CALCULATION OF LEAST SQUARE PLANE===\n\n"
	return planeCoeff
###END FUNCTION getLstSqrPlaneLsqr(points)###


def buildRingHash():
	#print coord['A'][1]['RES_NAME']

	ringId = 0

	for chain in coord.keys():
		for resNum in coord[chain].keys():
			if coord[chain][resNum]['RES_NAME'] in piRingDef:
				#print chain," ",resNum," ",coord[chain][resNum]['RES_NAME']
				pts = infinite_defaultdict()
				atomNums = infinite_defaultdict()
				altLocs = infinite_defaultdict()
				for atName in coord[chain][resNum].keys():
					if atName in piRingDef[coord[chain][resNum]['RES_NAME']]:
						for altLoc in coord[chain][resNum][atName].keys():
							altLocs[altLoc] = 1
							if altLoc not in pts:
								pts[altLoc] = []
							pts[altLoc].append([coord[chain][resNum][atName][altLoc]['X'],coord[chain][resNum][atName][altLoc]['Y'],coord[chain][resNum][atName][altLoc]['Z']])

							if altLoc not in atomNums:
								atomNums[altLoc] = []
							atomNums[altLoc].append(coord[chain][resNum][atName][altLoc]['ATOM_NUM'])

				###END FOR###

				###CALCULATE CENTROID OF THE RING
				###NOTE: RESIDUE IS ADDED TO ringHash ONLY IF IT HAS AT LEAST 3 ATOMS OF RING.
				###      PLANE FITTING WILL GIVE ERROR WHEN LESS THAN 3 POINTS ARE CONSIDERED.
				###      ALSO, RING WITH ONLY 1 OR 2 ATOMS IS NOT WORTH CONSIDERING.
				#print chain,resNum
				for altLoc in altLocs.keys():
					if len(pts[altLoc]) > 2:
						cen = calcCentroid(pts[altLoc])
						ringHash[ringId]['CENTROID'] = {'X':cen[0], 'Y':cen[1], 'Z':cen[2]}

						pln = getLstSqrPlane(pts[altLoc])
						#print ringId,ringHash[ringId]['CENTROID']['X']
	#					print cen,",",atomCoord[atomNums[0]]['X'],atomCoord[atomNums[0]]['Y'],atomCoord[atomNums[0]]['Z']
						#v = [atomCoord[atomNums[0]]['X']-cen[0],atomCoord[atomNums[0]]['Y']-cen[1],atomCoord[atomNums[0]]['Z']-cen[2]]
						#v = [atomCoord[atomNums[1]]['X']-cen[0],atomCoord[atomNums[1]]['Y']-cen[1],atomCoord[atomNums[1]]['Z']-cen[2]]
						#p = [pln[0],pln[1],pln[2]]
						#print "*",math.degrees(angle2Vectors(v,p))

						###CHECK THE DIRECTION OF NORMAL TO PLANE WITH RESPECT TO CA OF THE SAME RESIDUE
						###NOTE: ALT_LOC IS SOMETIMES GIVEN ONLY FOR SIDE CHAIN ATOMS AND ALT_LOC FOR MAIN CHAIN ATOMS IS KEPT " ".
						###FOLLOWING IF CONDITION CONSIDERS THIS ISSUE.
						if(altLoc not in coord[chain][resNum]['CA']):
							altLoc = " "
							#print str(coord[chain][resNum]['CA'][altLoc]['X']) + " " + str(coord[chain][resNum]['CA'][altLoc]['Y']) + " " + str(coord[chain][resNum]['CA'][altLoc]['Z'])

						caCoord = [ coord[chain][resNum]['CA'][altLoc]['X'],coord[chain][resNum]['CA'][altLoc]['Y'],coord[chain][resNum]['CA'][altLoc]['Z'] ]

						#print str(ringHash[ringId]['CENTROID']['X']) + " " + str(ringHash[ringId]['CENTROID']['Y']) + " " + str(ringHash[ringId]['CENTROID']['Z'])
						#print str(caCoord) + "\n"

						if math.degrees(angle2Vectors(vector([ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z']],caCoord),[pln[0],pln[1],pln[2]])) > 90:
							pln[0] = -pln[0]
							pln[1] = -pln[1]
							pln[2] = -pln[2]


						###PLANE IS IN THE FORMAT GIVEN BELOW
						###PLANE: a*X + b*Y + c*Z + d = 0
						###THE VECTOR STORED IS [a,b,c,d]
						ringHash[ringId]['PLANE'] = pln
						ringHash[ringId]['CHAIN'] = chain
						ringHash[ringId]['RES_NUM'] = resNum
						ringHash[ringId]['RES_NAME'] = coord[chain][resNum]['RES_NAME']
						ringHash[ringId]['ATOM_NUMS'] = atomNums[altLoc]
						ringHash[ringId]['ALT_LOC'] = altLoc

						"""
						#TEST PRINT
						print pln,"\n----------------------\n"
						print "CA coord: ",caCoord
						print "ALT_LOC: ",ringHash[ringId]['ALT_LOC']
						print "Centriod coord: ",ringHash[ringId]['CENTROID']
						print "Vector CA->Centroid: ", vector([ringHash[ringId]['CENTROID']['X'],ringHash[ringId]['CENTROID']['Y'],ringHash[ringId]['CENTROID']['Z']],caCoord)
						print "CA.Centriod: ",dotProd([1,1,1],[1,0,0])
						print "Modulus: ",mod([1,2,3])
						print "Angle2Vectors: ",math.degrees(angle2Vectors([1,1,1],[1,0,0]))
						print ringHash[ringId]['ATOM_NUMS']
						"""				
						ringId += 1

#PRINT ringHash
#	for i in ringHash.keys():
#		for j in ringHash[i].keys():
#			print i," : ",j," : ",ringHash[i][j]
#		print ""
#END PRINT
###END FUNCTION buildRingHash()###


def buildCationHash():
	cationId = 0

	for chain in coord.keys():
		for resNum in coord[chain].keys():
			if coord[chain][resNum]['RES_NAME'] in cationDef.keys():
				pts = infinite_defaultdict()
				wts = infinite_defaultdict()
				altLocs = infinite_defaultdict()
				atomNums = infinite_defaultdict()
				#print chain + "\t" + resNum + "\t" + coord[chain][resNum]['RES_NAME']
				for atName in cationDef[coord[chain][resNum]['RES_NAME']]:
					for altLoc in coord[chain][resNum][atName].keys():
						#print "altLoc = " + altLoc
						altLocs[altLoc] = 1
						if altLoc not in pts:
							pts[altLoc] = []
							wts[altLoc] = []
						pts[altLoc].append([coord[chain][resNum][atName][altLoc]['X'],coord[chain][resNum][atName][altLoc]['Y'],coord[chain][resNum][atName][altLoc]['Z']])
						wts[altLoc].append(mass[coord[chain][resNum][atName][altLoc]['ELEMENT']])

						if altLoc not in atomNums:
							atomNums[altLoc] = []
						atomNums[altLoc].append(coord[chain][resNum][atName][altLoc]['ATOM_NUM'])


				#print pts
				#print wts
				for altLoc in altLocs.keys():
					cm = calcCenterOfMass(pts[altLoc],wts[altLoc])
					cen = calcCentroid(pts[altLoc])
					#print "cm = " + str(cm)
					#print "cen = " + str(cen)
					cationHash[cationId]['CHAIN'] = chain
					cationHash[cationId]['RES_NUM'] = resNum
					cationHash[cationId]['RES_NAME'] = coord[chain][resNum]['RES_NAME']
					cationHash[cationId]['ATOM_NUMS'] = atomNums[altLoc]
					cationHash[cationId]['ALT_LOC'] = altLoc
					cationHash[cationId]['CM'] = {'X':cm[0], 'Y':cm[1], 'Z':cm[2]}

					cationId += 1
###END FUNCTION buildCationHash()###


def buildXhHash():
	xhId = 0

	for chain in coord.keys():
		for resNum in coord[chain].keys():
			for atNameX in coord[chain][resNum].keys():
				#OMIT KEY NAME 'RES_NAME' AND CARBOLYL CARBON. PYMOL ADDS 'H' TO CARBONYL CARBON IN STEAD OF 'OH' GROUP.
				#THIS MAKES IT C(H)=O. THIS IS ALDEHYDE GROUP AND NOT CARBONYL AS IT SHOULD BE. HENCE IGNORED.
				if atNameX != 'RES_NAME' and atNameX != 'C':
					for altLocX in coord[chain][resNum][atNameX].keys():
						if coord[chain][resNum][atNameX][altLocX]['ELEMENT'] != 'H':
							#X ATOM IS SELECTED
							#RUN LOOP ON ALL ATOMS AGAIN TO SELECT H ATOMS ONE BY ONE
							for atNameH in coord[chain][resNum].keys():
								if atNameH != 'RES_NAME':
									for altLocH in coord[chain][resNum][atNameH].keys():
										#CHECK IF ALT_LOC OF BOTH X AND H ATOMS ARE SAME.
										if altLocX == altLocH:
											if coord[chain][resNum][atNameH][altLocH]['ELEMENT'] == 'H':
												#H ATOM IS SELECTED
												#CHECK IF H ATOM IS CONNECTED TO X ATOM USING xhCutoffDist
												if (coord[chain][resNum][atNameH][altLocH]['X'] < coord[chain][resNum][atNameX][altLocX]['X'] + xhCutoffDist and coord[chain][resNum][atNameH][altLocH]['X'] > coord[chain][resNum][atNameX][altLocX]['X'] - xhCutoffDist) & (coord[chain][resNum][atNameH][altLocH]['Y'] < coord[chain][resNum][atNameX][altLocX]['Y'] + xhCutoffDist and coord[chain][resNum][atNameH][altLocH]['Y'] > coord[chain][resNum][atNameX][altLocX]['Y'] - xhCutoffDist) & (coord[chain][resNum][atNameH][altLocH]['Z'] < coord[chain][resNum][atNameX][altLocX]['Z'] + xhCutoffDist and coord[chain][resNum][atNameH][altLocH]['Z'] > coord[chain][resNum][atNameX][altLocX]['Z'] - xhCutoffDist):
													if dist([ coord[chain][resNum][atNameX][altLocX]['X'],coord[chain][resNum][atNameX][altLocX]['Y'],coord[chain][resNum][atNameX][altLocX]['Z'] ],[ coord[chain][resNum][atNameH][altLocH]['X'],coord[chain][resNum][atNameH][altLocH]['Y'],coord[chain][resNum][atNameH][altLocH]['Z'] ]) < xhCutoffDist:
														#print resNum,coord[chain][resNum]['RES_NAME'],atNameX,atNameH
														xhHash[xhId]['CHAIN'] = chain
														xhHash[xhId]['RES_NUM'] = resNum
														xhHash[xhId]['RES_NAME'] = coord[chain][resNum]['RES_NAME']
														xhHash[xhId]['X_ATOM'] = {'ATOM_NAME':atNameX, 'ATOM_NUM':coord[chain][resNum][atNameX][altLocX]['ATOM_NUM'], 'ALT_LOC':altLocX, 'X':coord[chain][resNum][atNameX][altLocX]['X'], 'Y':coord[chain][resNum][atNameX][altLocX]['Y'], 'Z':coord[chain][resNum][atNameX][altLocX]['Z'], 'ELEMENT':coord[chain][resNum][atNameX][altLocX]['ELEMENT']}
														xhHash[xhId]['H_ATOM'] = {'ATOM_NAME':atNameH, 'ATOM_NUM':coord[chain][resNum][atNameH][altLocH]['ATOM_NUM'], 'ALT_LOC':altLocH, 'X':coord[chain][resNum][atNameH][altLocH]['X'], 'Y':coord[chain][resNum][atNameH][altLocH]['Y'], 'Z':coord[chain][resNum][atNameH][altLocH]['Z'], 'ELEMENT':coord[chain][resNum][atNameH][altLocH]['ELEMENT']}
														xhId += 1

	"""
#TEST PRINT xhHash
	print "PRINTING XH HASH\n"
	for i in xhHash.keys():
		for j in xhHash[i].keys():
			print i,j,xhHash[i][j]
		for k in xhHash[i]['X_ATOM'].keys():
			print "\tX: ",k,xhHash[i]['X_ATOM'][k]
		for k in xhHash[i]['H_ATOM'].keys():
			print "\tH: ",k,xhHash[i]['H_ATOM'][k]
#END TEST PRINT xhHash
	"""

###END FUNCTION buildXhHasg()###


def dist(p1,p2):
	s = 0
	if len(p1) == len(p2):
		i = 0
		while i < len(p1):
			s += (p1[i]-p2[i])**2
			i += 1

	return math.sqrt(s)
###END FUNCTION dist(p1,p2)###


def vector(p1,p2):
	v = []
	if len(p1) == len(p2):
		i = 0
		while i < len(p1):
			v.append(p2[i]-p1[i])
			i += 1
	return v
###END FUNCTION vector(p1,p2)###


def dotProd(v1,v2):
	prod = 0
	if len(v1) == len(v2):
		i = 0
		while i < len(v1):
			prod += (v1[i]*v2[i])
			i += 1
	return prod
###END FUNCTION dotProd(p1,p2)###


def mod(v):
	s = 0
	i = 0
	while i < len(v):
		s += v[i]**2
		i += 1
	return math.sqrt(s)
###END FUNCTION mod(v)###

def angle2Vectors(v1,v2):
	if len(v1) == len(v2):
		return math.acos( dotProd(v1,v2) / (mod(v1)*mod(v2)) )

	return 0
###END FUNCTION angle2Vectors(v1,v2)###


######################################################################
######################################################################

#print math.degrees(angle2Vectors([0,1,0],[1,1,0]))
#print dotProd([0,1,0],[1,1,0])

#pts = [[0,1,2],[0,2,3],[0.01,6,3],[0,2,1],[0,4,7]]

#pln = getLstSqrPlane(pts)
#p = [pln[0],pln[1],pln[2]]

#v = vector([0,1,2],[0,2,3])

#print math.degrees(angle2Vectors(v,p))

#print "------------------------------------------"
#print mypdb.filename,"*"

indir = sys.argv[1]+"/pdb"

tablesOutDir = sys.argv[2]

choTable = "choTable"
xhpiTable = "xhpiTable"
pipiTable = "pipiTable"
xhTable = "xhTable"
ringTable = "ringTable"
cationTable = "cationTable"
cationPiTable = "cationpiTable"

choTableFile = open(tablesOutDir+"/"+choTable,'w')
xhpiTableFile = open(tablesOutDir+"/"+xhpiTable,'w')
pipiTableFile = open(tablesOutDir+"/"+pipiTable,'w')
xhTableFile = open(tablesOutDir+"/"+xhTable,'w')
ringTableFile = open(tablesOutDir+"/"+ringTable,'w')
cationTableFile = open(tablesOutDir+"/"+cationTable,'w')
cationPiTableFile = open(tablesOutDir+"/"+cationPiTable,'w')

files = "*.pdb"

file_list = glob.glob(indir+"/"+files)

print "Reading input directory: "+indir+"\n"

#choLines.append(pdbid+"\t"+str(xhId)+"\t"+oChain+"\t"+oResNum+"\t"+str(co)+"\t"+str(ho)+"\t"+str(cho)+"\t"+str(hoc)+"\n")
choTableFile.write("PDB_ID\tXHID\tO_CHAIN_ID\tO_RES_NUM\tO_ATOM_NUM\tO_ALT_LOC\tC_O\tH_O\tC_H_O\tH_O_C\n")
xhpiTableFile.write("PDB_ID\tXHID\tRINGID\tX_PIM\tH_PIM\tX_H_PIM\tX_PIM_PIN\n")
pipiTableFile.write("PDB_ID\tRINGID1\tRINGID2\tCEN_CEN_DIST\tPIN_PIN_ANGLE\tCLOSE_ATOM1\tCLOSE_ATOM2\tCLOSEST\tALT_LOC1\tFAR_ATOM1\tFAR_ATOM2\tFARTHEST\tALT_LOC2\n")
xhTableFile.write("PDB_ID\tXHID\tCHAIN_ID\tRES_NUM\tX_ATOM_NAME\tX_ATOM_NUM\tH_ATOM_NAME\tH_ATOM_NUM\tALT_LOC\n")
ringTableFile.write("PDB_ID\tRINGID\tCHAIN_ID\tRES_NUM\tRING_ATOM_NUMS\tALT_LOC\tCEN_X\tCEN_Y\tCEN_Z\tRING_NORMAL\n")
cationTableFile.write("PDB_ID\tCATIONID\tCHAIN_ID\tRES_NUM\tCATION_ATOM_NUMS\tALT_LOC\tCEN_X\tCEN_Y\tCEN_Z\n")
cationPiTableFile.write("PDB_ID\tCATIONID\tRINGID\tCAT_PIM\tCAT_PIM_PIN\n")

if file_list:
	file_list.sort()
	cnt = 0
	for filename in file_list:
		#matchObj = re.match(r'.*/(.+?)(_.)?\.pdb',filename,re.S)

		###THIS MIGHT BE GOOD WAY TO NAME THE FILES, TO SPLIT THE NAME IN THREE MEANINGFUL PARTS, BUT IT IS VERY DIFFICULT TO FOLLOW EVERYTIME.
		###HENCE HIS DEFINITION IS DROPPED AND WHATEVER IS EXCEPT THE FILE EXTENTION (.pdb) IS TAKEN AS pdbid.
		#matchObj = re.match(r'.*/(....)(.*?)_?(.?)\.pdb',filename,re.S)
		matchObj = re.match(r'.*/(.+)\.pdb',filename,re.S)
		pdbid = matchObj.group(1)
		#print "***"+matchObj.group(1)+" "+matchObj.group(2)+" "+matchObj.group(3)
		print "Processing PDB ID " + pdbid + " : " + filename + " ..."

		mypdb = pdb3.Pdb3(filename)
		mypdb.setCoordData()

		coord = mypdb.pdbCoordData
		atomCoord = mypdb.atomCoordData

###BUILD cationHash
		cationHash = infinite_defaultdict()
		buildCationHash()

###BUILD ringHash
		ringHash = infinite_defaultdict()
		buildRingHash()

#TEST PRINT ringHash
#		for i in ringHash.keys():
#			for j in ringHash[i].keys():
#				print i," : ",j," : ",ringHash[i][j]#		print ""
#END PRINT


###BUILD xhHash
		xhHash = infinite_defaultdict()
		buildXhHash()

#TEST PRINT xhHash
#		for i in xhHash.keys():
#			for j in xhHash[i].keys():
#				print i,j,xhHash[i][j]
#			for k in xhHash[i]['X_ATOM'].keys():
#				print "\tX: ",k,xhHash[i]['X_ATOM'][k]
#			for k in xhHash[i]['H_ATOM'].keys():
#				print "\tH: ",k,xhHash[i]['H_ATOM'][k]
#END TEST PRINT xhHash


###FIND CATION-PI INTERACTIONS AND WRITE cationPiTable
		cationPiLines = findCationPiInteractions(pdbid)
		cationPiTableFile.writelines(cationPiLines)


###FIND CH-O INTERACTIONS AND WRITE chOTable
		choLines = findChOInteractions(pdbid)
		choTableFile.writelines(choLines)


###FIND XH-PI INTERACTIONS AND WRITE xhpiTable
		xhpiLines = findXhPiInteractions(pdbid)
		xhpiTableFile.writelines(xhpiLines)


###FIND PI-PI INTERACTIONS AND WRITE pipiTable
		pipiLines = findPiPiInteractions(pdbid)
		pipiTableFile.writelines(pipiLines)


###WRITE XH TABLE
		for xhId in xhHash.keys():
			xhLine = ""
			xhLine += pdbid + "\t" + str(xhId) + "\t" + xhHash[xhId]['CHAIN'] + "\t" + xhHash[xhId]['RES_NUM'] + "\t"
			xhLine += xhHash[xhId]['X_ATOM']['ATOM_NAME'] + "\t" + str(xhHash[xhId]['X_ATOM']['ATOM_NUM']) + "\t"
			xhLine += xhHash[xhId]['H_ATOM']['ATOM_NAME'] + "\t" + str(xhHash[xhId]['H_ATOM']['ATOM_NUM']) + "\t"
			xhLine += xhHash[xhId]['X_ATOM']['ALT_LOC'] + "\n"
			xhTableFile.write(xhLine)


###WRITE PI RING TABLE
		for ringId in ringHash.keys():
			ringLine = ""
			ringLine += pdbid + "\t" + str(ringId) + "\t" + ringHash[ringId]['CHAIN'] + "\t" + ringHash[ringId]['RES_NUM'] + "\t"
			ringLine += ",".join(map(lambda(x): str(x),ringHash[ringId]['ATOM_NUMS'])) + "\t" + ringHash[ringId]['ALT_LOC'] + "\t"
			ringLine += str(ringHash[ringId]['CENTROID']['X']) + "\t" + str(ringHash[ringId]['CENTROID']['Y']) + "\t" + str(ringHash[ringId]['CENTROID']['Z']) + "\t"
			ringLine += ",".join(map(lambda(x): str(x),ringHash[ringId]['PLANE'])) + "\n"
			ringTableFile.write(ringLine)

###WRITE CATION TABLE
		for cationId in cationHash.keys():
			cationLine = ""
			cationLine += pdbid + "\t" + str(cationId) + "\t" + cationHash[cationId]['CHAIN'] + "\t" + cationHash[cationId]['RES_NUM'] + "\t"
			cationLine += ",".join(map(lambda(x): str(x),cationHash[cationId]['ATOM_NUMS'])) + "\t" + cationHash[cationId]['ALT_LOC'] + "\t"
			cationLine += str(cationHash[cationId]['CM']['X']) + "\t" + str(cationHash[cationId]['CM']['Y']) + "\t" + str(cationHash[cationId]['CM']['Z'])
			cationLine += "\n"
			cationTableFile.write(cationLine)



###CLEAR THE TWO DICTIONARIES, OTHERWISE NEXT KEYS WILL BE APPENDED TO THE ORIGINALLY PRESENT DICTIONARIES.
		mypdb.pdbCoordData.clear()
		mypdb.atomCoordData.clear()

		cnt += 1
		print "#" + str(cnt) + "\nDONE\n"

choTableFile.close()
xhpiTableFile.close()
pipiTableFile.close()
xhTableFile.close()
ringTableFile.close()

