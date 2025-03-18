# check-database-integrity.sh

Check if given compressed MySQL Database dumps are complete.

The script will take the list of one day old databases files (compressed gz) from specified location (/home/mysqlbackup/), first to a file and then loaded to an array. 
The database is checked for the string "Dump completed on" and then written to a log file. 
The execution is done as jobs, to enable multiple databases to be checked concurrently, decreasing execution time. (Here the value is 30)
All logs are stored in a location (/usr/local/mysql-temp/) and logs older than 5 days are removed. 
The results are pushed into slack. 

Execution time:
For 10 1.6GB compressed (gz) database dump files, it will take ~2 minutes when all the 10 are executed concurrently. 

You can add a cronjob similar to below to check this regularly.

0 12 * * * /bin/bash /root/check-db-integrity.sh > /usr/local/mysql-temp/\`date "+\%d"\`-check-db-integrity-execution.log 2> /usr/local/mysql-temp/\`date "+\%d"\`-check-db-integrity-execution-err.log


# check-docroot.sh
Check Document Root of domains in cPanel, CWP, Apache and Nginx


# check-server-details.sh
To check general Linux server details.

The script will check the following:

1. Hostname
2. OS Version
3. cPanel/CWP Version
4. Apache Version
5. Kernel Release


# db-table-restore
Restore specific tables from a database dump

One can change the table name and add n number of tables in the script. They will be loaded into the array.
Remember to edit the database credentials.

# enable-cw-cpu-status
Copy script and run the script providing instance name and profile.
Choose and confirm parameters like Instance ID, SNS, Alarm Name.

The script will enable CPU utilization alarm for greater than 90% and Status check alarm (with reboot) with action as specified existing SNS topic. 

# ami_checker_delete.sh
Script to Check AMI and delete unused

Conditions that are checked by the Script:
Check if the AMI has a tag - DeletionProtection value Yes
Check if the AMI is used by any current instance.
Check if the AMI is in any AutoScaling Group.
Check if the AMI is in any Launch Template (last 2 versions).
Check if the AMI is in any Launch Configuration.
Check if the AMI is in Elastic Beanstalk environments.
Check if the AMI is in Spot Instance requests

Working:
From one account, it will take the list if all AMI and check for any one of the 7 condition above. If any is found, it will be ignored. If not, then we will be asked for a prompt if we need to delete that AMI. Choosing Y/y will delete that AMI and associated snapshots.
Manual exclusion of AMI for different clients in the environments:
This requires the AMI to have a tag - DeletionProtection value Yes . All AMI with this tag is ignored and won’t be deleted.

Execution:
This script can be executed with AWS CLI RW privilege for any users on our bastion. They will need to have a .aws/config file with all the required clients. A sample of execution for Phobs-Dev account is attached.
We can add this as cron for clients to run every month or can manually run during an audit to clean up the AMIs.

It will give an output like below incase the AMI is detected in Spot request:

```
Taking AMI ami-06ae23b3c92c1db60
This AMI is currently in use for Instance.
This AMI is currently in use for Spot Instance requests sfr-03ea09e3-1111-3332-8c5d-4565245467.
IN USE - This AMI ami-06ae23b3c92c1db60 is currently in use, so not deleting.
Below is an output incase we select N/n instead of Y and it will check for the next AMI.
Taking AMI ami-0ef501c8v50e96eaa
NOT IN USE - This AMI ami-0ef501c8v50e96eaa is not in use, so deleting.
Do you want to proceed with deletion? (Y/N)
n
Deletion canceled. Exiting...

Taking AMI ami-0321b89f2340582b9
NOT IN USE - This AMI ami-0321b89f2340582b9 is not in use, so deleting.
Do you want to proceed with deletion? (Y/N)
y
===================================
ami-0321b89f2340582b9
snap-05bae34549f88f98d
===================================
```


