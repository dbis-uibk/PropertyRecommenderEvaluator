#!/bin/bash -e

DIR_NAME="$(dirname $0)"

if [ $# -ne 5 ]
then
	echo "USAGE: $0 <json-dump-input> <host> <user> <password> <database-name>";
else
	echo "Converting JSON dump to SQL dump! This may take several hours!";

	php ${DIR_NAME}/jsonToSQL.php $1 ${1}.sql;

	echo -e "Conversion finished! SQL dump \"$1\".sql created!\n";

	echo "Importing into database!";
	command -v pv > /dev/null && { 
		# pv command exists
		pv ${1}.sql | mysql -h $2 -u $3 -p${4} $5;
 	} || {
		# pv command doesn't exist
		mysql -h $2 -u $3 -p${4} $5 < ${1}.sql;
  }
	echo "Import finished!";
fi
