#!bin/bash

cd $1/pdb
#: <<'END'
if [ "$2" = "update_hydrogens" ]
then
	echo "---UPDATE HYDROGENS---"
	echo "perl removeAddHydrogens.pl $2\n"
	perl removeAddHydrogens.pl update_hydrogens
elif [ "$2" = "only_add_hydrogens" ]
then
	echo "---ADD HYDROGENS---"
	echo "perl removeAddHydrogens.pl\n"
	perl removeAddHydrogens.pl
else
	echo "---NO REMOVE/ADD HYDROGENS---"
fi
echo "\n---END REMOVE/ADD HYDROGENS---\n"


###RUN DSSP
cd ../pdbDssp
echo "---DSSP---"
echo "runDssp.pl\n"
perl runDssp.pl
echo "\n---END DSSP---\n";

###RUN CLEAN
cd ../pdbClean
echo "---CLEAN---"
echo "cleanPdb.pl\n"
perl cleanPdb.pl
rm fort.15
echo "\n---END CLEAN---\n"
#END
###RUN HBPLUS
cd ../pdbHbplus
echo "---HBPLUS---"
echo "hbplusPdb.pl\n"
perl hbplusPdb.pl
echo "\n---END HBPLUS---\n"
#: <<'END'
###RUN NACCESS
cd ../pdbNaccess
echo "---NACCESS---"
echo "naccessPdb.pl\n"
perl naccessPdb.pl
echo "\n---END NACCESS---\n"

###RUN PROMOTIF
cd ../promotifResults
echo "---PROMOTIF---"
echo "runPromotif_singleFiles.pl\n"
perl runPromotif_singleFiles.pl
echo "\n---END PROMOTIF---\n"

###RUN PROBE
cd ../pdbProbe
echo "---PROBE---"
echo "probePdb.pl\n"
perl probePdb.pl
echo "\n---END PROBE---\n"
#END
