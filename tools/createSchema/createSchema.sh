#!/bin/bash -e

DIR_NAME="$(dirname $0)"

if [ $# -ne 4 ]
then
	echo "USAGE: $0 <host> <user> <password> <database-name>";
else
	echo "Creating Tables and Procedures";
	echo ${BASE_NAME}
	# create empty tables
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/tabledef.sql; 

	# create the procedures for the wikidata import tool
 	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/insertTriple.sql;
 	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createStatsAfterImport.sql;

	# create the procedure to create a testset for the evaluation
 	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createRandSub.sql;
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createReconstructOrder.sql;

	# create the procedures to create the rules for the python eval framework
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createRules.sql;
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createClassifiedRules.sql;
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createObjectRules.sql;
	mysql -h $1 -u $2 -p${3} $4 < ${DIR_NAME}/sql/createObjectPropertyRules.sql;

	echo "Finished!";
fi
