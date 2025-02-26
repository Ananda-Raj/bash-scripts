#!/bin/bash

# Script to check Web Server details
# Author: Ananda Raj
# Date: 08 Sep 2019

# Check Hostname
echo -e "\nHOSTNAME: `hostname`";

# Check OS Version
if [ -f "/etc/redhat-release" ];
        then
        echo "OS VERSION: `cat /etc/redhat-release`";
elif [ -f "/usr/bin/lsb_release" ];
        then
        echo "OS VERSION: `lsb_release -d | awk '{print $2" "$3" "$4" "$5}'`";
else
        echo -e "\nCouldn't Find OS Version\n";
fi

# Check cPanel/CWP Version
if [ -f "/usr/local/cpanel/cpanel" ];
        then
        echo "CPANEL VERSION: `/usr/local/cpanel/cpanel -V`";
elif [ -f "/usr/local/cwpsrv/htdocs/resources/admin/include/version.php" ];
        then
        echo "CWP VERSION: `grep version /usr/local/cwpsrv/htdocs/resources/admin/include/version.php | awk '{print $NF}'| tr -d '"|;'`";
else
        echo -e "\nCouldn't Find cPanel / CWP\n";
fi

# Check Apache Version
if [ -f "/usr/local/apache/bin/httpd" ];
        then
        echo "APACHE VERSION: `/usr/local/apache/bin/httpd -v | grep "Server version" | awk '{print $3" "$4" "$5}'`";
else
        echo -e "\nCouldn't Find Apache\n";
fi

# Check Kernel Release
echo -e "KERNEL RELEASE: `uname -r`\n";
