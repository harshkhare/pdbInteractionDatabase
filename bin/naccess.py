import re
from collections import defaultdict
import os.path

def infinite_defaultdict():
	return defaultdict(infinite_defaultdict)
###END infinite_deraultdict()###


class Naccess :

	def __init__(self,asaFilename,rsaFilename):
		self.asaFilename = asaFilename
		self.rsaFilename = rsaFilename

		self.asaData = infinite_defaultdict()
		self.rsaData = infinite_defaultdict()
		self.chainData = infinite_defaultdict()
		self.totalData = infinite_defaultdict()
###END __init__()###


	def setNaccessData(self):
		if os.path.exists(self.asaFilename):
			self.setAsaData()
		else:
			print "WARNING: ASA file not found. : " + self.asaFilename
		if os.path.exists(self.rsaFilename):
			self.setRsaData()
		else:
			print "WARNING: RSA file not found. : " + self.rsaFilename


	def setRsaData(self):
		print "Class Naccess :: setRsaData() :: Opening file",self.rsaFilename
		rsafile = open(self.rsaFilename,'r')
		lines =  rsafile.readlines()
		
		for line in lines:

			if line.startswith('RES'):
				#======================REM= =RES _ NUM=      All-atoms   Total-Side   Main-Chain    Non-polar    All polar
				#======================REM=           =     ABS   REL    ABS   REL    ABS   REL    ABS   REL    ABS   REL
				#RES SER A  32B  143.14 122.9  94.79 121.4  48.35 125.9  61.63 126.9  81.51 120.0
				#======================RES= =SER== ==A==  32B=  =143.14= =122.9= = 94.79= =121.4= = 48.35= =125.9= = 61.63= =126.9= = 81.51= =120.0=
				matchObj = re.match(r'(...).(...)(.)(.)(.....)..(......).(.....).(......).(.....).(......).(.....).(......).(.....).(......).(.....)',line,re.S)
				RES_NAME = matchObj.group(2).strip()
				CHAIN = matchObj.group(4).strip()
				RES_NUM = matchObj.group(5).strip()
				ALL_ABS = float(matchObj.group(6).strip())
				ALL_REL = float(matchObj.group(7).strip())
				SC_ABS = float(matchObj.group(8).strip())
				SC_REL = float(matchObj.group(9).strip())
				MC_ABS = float(matchObj.group(10).strip())
				MC_REL = float(matchObj.group(11).strip())
				NP_ABS = float(matchObj.group(12).strip())
				NP_REL = float(matchObj.group(13).strip())
				P_ABS = float(matchObj.group(14).strip())
				P_REL = float(matchObj.group(15).strip())

				#print RES_NAME + " " + CHAIN + " " + RES_NUM + " " + str(ALL_ABS) + " " + str(ALL_REL) + " " + str(SC_ABS) + " " + str(SC_REL) + " " + str(MC_ABS) + " " + str(MC_REL) + " " + str(NP_ABS) + " " + str(NP_REL) + " " + str(P_ABS) + " " + str(P_REL)
				self.rsaData[CHAIN][RES_NUM] = {'RES_NAME':RES_NAME, 'ALL_ABS':ALL_ABS, 'ALL_REL':ALL_REL, 'SC_ABS':SC_ABS, 'SC_REL':SC_REL, 'MC_ABS':MC_ABS, 'MC_REL':MC_REL, 'NP_ABS':NP_ABS, 'NP_REL':NP_REL, 'P_ABS':P_ABS, 'P_REL':P_REL}


			if line.startswith('CHAIN'):
				#CHAIN  1 A     7814.5       6344.5       1470.0       4672.6       3141.9
				#======================CHAIN= = 1= =A=    = 7814.5=      = 6344.5=      = 1470.0=      = 4672.6=      = 3141.9=
				matchObj = re.match(r'(.....).(..).(.)....(.......)......(.......)......(.......)......(.......)......(.......)',line,re.S)
				CHAIN_NUM = matchObj.group(2).strip()
				CHAIN = matchObj.group(3)
				ALL = float(matchObj.group(4).strip())
				SC = float(matchObj.group(5).strip())
				MC = float(matchObj.group(6).strip())
				NP = float(matchObj.group(7).strip())
				P = float(matchObj.group(8).strip())

				#print CHAIN_NUM + " " + CHAIN + " " + str(ALL) + " " + str(SC) + " " + str(MC) + " " + str(NP) + " " + str(P)
				self.chainData[CHAIN] = {'ALL':ALL, 'SC':SC, 'MC':MC, 'NP':NP, 'P':P}

			if line.startswith('TOTAL'):
				#TOTAL         15590.4      12657.0       2933.5       9386.6       6203.8
				#======================TOTAL= =  = = =    =15590.4=      =12657.0=      = 2933.5=      = 9386.6=      = 6203.8=
				matchObj = re.match(r'(.....).(..).(.)....(.......)......(.......)......(.......)......(.......)......(.......)',line,re.S)
				ALL = float(matchObj.group(4).strip())
				SC = float(matchObj.group(5).strip())
				MC = float(matchObj.group(6).strip())
				NP = float(matchObj.group(7).strip())
				P = float(matchObj.group(8).strip())

				#print "   " + str(ALL) + " " + str(SC) + " " + str(MC) + " " + str(NP) + " " + str(P)
				self.totalData = {'ALL':ALL, 'SC':SC, 'MC':MC, 'NP':NP, 'P':P}


	def setAsaData(self):
		print "Class Naccess :: setAsaData() :: Opening file",self.asaFilename
		asafile = open(self.asaFilename,'r')
		lines =  asafile.readlines()
		
		for line in lines:

			#ATOM      1  N   GLY A   9     -12.633   5.773  16.769  34.976  1.65
			#                     =ATOM  ==    2== == CA == ==GLY== ==A==   9 ==   == -12.994==   4.762==  15.711== ==  9.243==  1.87
			matchObj = re.match(r'(......)(.....)(.)(....)(.)(...)(.)(.)(.....)(...)(........)(........)(........)(.)(.......)(......)\n*',line,re.S)

			#TAG = matchObj.group(1).strip()
			ATOM_NUM = int(matchObj.group(2).strip())
			#BLANK1 = matchObj.group(3).strip()
			ATOM_NAME = matchObj.group(4).strip()
			ALT_LOC = matchObj.group(5).strip()
			RES_NAME = matchObj.group(6).strip()
			#BLANK2 = matchObj.group(7).strip()
			CHAIN = matchObj.group(8).strip()
			RES_NUM = matchObj.group(9).strip()
			#BLANK3 = matchObj.group(10).strip()
			#X = float(matchObj.group(11).strip())
			#Y = float(matchObj.group(12).strip())
			#Z = float(matchObj.group(13).strip())
			ASA = float(matchObj.group(15).strip())
			RAD = float(matchObj.group(16).strip())

###ALT_LOC IS KEPT AS ' ' WHEN NOT SPECIFIED.
			if ALT_LOC == '':
				ALT_LOC = ' '


			#print str(ASA) + " " + str(RAD)
			self.asaData[CHAIN][RES_NUM][ATOM_NAME][ALT_LOC] = {'ASA':ASA, 'RAD':RAD}


