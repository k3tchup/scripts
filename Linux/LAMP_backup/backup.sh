#!/bin/sh

# Backup script for LAMP database and source code

# Setting defaults

wwwdocs=/var/www/html/
mysqldump_path=/usr/bin/mysqldump
database=user
db_user=pass
db_pass=""
datetime=`date +%Y%m%d%k%M`
destination=/backups/
buuser=user
bugroup=pass

# backup MySQL database
echo "Backing up database, please wait..."
db_bu_name="/tmp/"$database"_dump_"$datetime".dmp"
$mysqldump_path -u $db_user --password="$db_pass" $database > $db_bu_name
echo "Database backed up."
echo "Backing up HTML directory, please wait..."
# tar HTML and db backup into a file
tar -czf $destination/"lamp_bu_"$database"_"$datetime.tar.gz /var/www/html $db_bu_name
echo "Backup complete."
chown $buuser:$bugroup $destination/"lamp_bu_"$database"_"$datetime.tar.gz /var/www/html $db_bu_name

# remove files older than 5 days
if [ "$?" = "0" ]; then
        find $destination -type f -mtime +5 -exec rm {} \;
fi



