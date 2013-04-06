#************************************** 
# It accomplishes the following task:
#------------------------------------
# 1. Your script will check if Apache, Mysql & PHP are installed. If not present, missing packages will be installed.
# 2. Then script will then ask user for domain name. (Suppose user enters example.com)
# 3. Create a /etc/hosts entry for example.com pointing to localhost IP.	
# 4. Create apache config file for example.com
# 5. Download WordPress latest version from http://wordpress.org/latest.zip and unzip it locally in example.com document root.
# 6. Create a new mysql database for new WordPress. (database name “example.com_db” )
# 7. Create wp-config.php with proper DB configuration. (You can use wp-config-sample.php as your template)
# 8. You may need to fix file permissions, cleanup temporary files, restart or reload apache config.
# 9. Tell user to open example.com in browser (if all goes well)
#------------------------------------
# Each Block will state about the task it is going to perform and assumptions made, if any.
# Possible Errors/Output are redirected to /dev/null.
# Created and Tested on Ubuntu 11.04. 
# Script only for Ubuntu Systems.
# Written By: geeksScript | Sanchit-(http://geeksScript.com), Dated: 02-04-2013.
#************************************** 

#!/bin/sh

package_check()
# This block checks whether Apache, Mysql, PHP(with php-mysql) are installed or not. If not, it will install the missing package by apt-get.
# After completing the task, it calls domain_name_task().
{
	for package in apache2 mysql php5 php5-mysql	
	do	
	echo "Checking '$package' installation..Please wait"
	sleep 1
	hash $package 2> /dev/null;
	if [ ! $? = 0 ]; then
		echo "Installing '$package'..Please wait"
		echo
		sleep 3;		
		sudo apt-get update 1> /dev/null;
		if [ $package = 'mysql' ]; then
			sudo apt-get -y install mysql-server;
		else
			sudo apt-get -y install $package;
		fi
		echo "Installed"
	else		
		echo "Installed"
		echo
	fi
	done
	domain_name_task
}

domain_name_task()
# This block ask the value of Domain Name from the user and creates a entry in /etc/hosts pointing to localhost.
# After completing the task, it calls the apache_task().
{
	echo	
	echo -n "Please enter a Domain Name:";
	read domain_name;
	sudo sh -c "echo 127.0.0.1 $domain_name >> /etc/hosts";
	echo
	echo "$domain_name entry created in /etc/hosts"
	echo
	apache_task
}

apache_task()
# This block creates a basic apache conf file of the domain name which user has entered.
# Conf file is created and updated in the /etc/apache2/sites-available folder and then is sym-linked in /etc/apache2/sites-enabled.
# It also makes a domain name folder in the DocumentRoot.
# Logs are saved in /var/log.
# After completing the task, it calls the wordpress_task().
{
	sudo chown $(hostname) /etc/apache2/sites-available /etc/apache2/sites-enabled
	sudo echo " <VirtualHost *:80>

  # Admin email, Server Name (domain name)
  ServerAdmin webmaster@$domain_name
  ServerName  $domain_name
  
  # Index file and Document Root (where the public files are located)
  DirectoryIndex index.html
  DocumentRoot /var/www/$domain_name

  # Custom log file locations
  LogLevel warn
  ErrorLog  /var/log/${domain_name}_error.log
  CustomLog /var/log/${domain_name}_access.log combined

</VirtualHost> " > /etc/apache2/sites-available/${domain_name}.conf
	sudo ln -s /etc/apache2/sites-available/${domain_name}.conf /etc/apache2/sites-enabled/${domain_name}.conf 2> /dev/null
	sudo chown root /etc/apache2/sites-available /etc/apache2/sites-enabled
	sudo mkdir /var/www/$domain_name 2> /dev/null
	echo "$domain_name apache conf file created and linked"
	echo
	wordpress_task
}

wordpress_task()
# This block downloads WordPress latest version from http://wordpress.org/latest.zip . Saves and unzip it locally in DocumentRoot.
# After completing the task, it calls the mysql_task().
{
	echo "Downloading latest version of Wordpress..Have Patience"; echo;
	sudo wget http://wordpress.org/latest.zip -O /var/www/$domain_name/latest.zip 1> /dev/null;
	sudo unzip /var/www/$domain_name/latest.zip -d /var/www/$domain_name/ 1> /dev/null;
	echo
	echo "Saved and Unzipped in /var/www/$domain_name/";
	mysql_task
}

mysql_task()
# This block creates a new mysql database for new WordPress with the name database_name_db.
# It will ask for MySql Username/Password from user. If user enters unvalid credentials, it will ask again for valid credentials.
# Password value will not be echo-ed back on screen.
# Since '.' character is not allowed in MySql DB name, it will be replace by '_' character.
# After completing the task, it calls the wp-config_task().
{
	domain_nm=$(echo $domain_name | sed 's/\./_/g')
	echo	
	echo "Creating mysql database $db_name";	
	echo -n "Please enter MySql username(eg. root):"
	read username;
	echo -n "Please enter MySql password:"
	stty -echo
	read password;
	stty echo
	db_name="${domain_nm}_db";
	mysql -u $username -p$password -Bse "CREATE DATABASE $db_name;"
	if [ ! $? = 0 ]; then
		echo
		echo "Username/Password Incorrect..Please try again"
		echo
		mysql_task
	else
	echo "$db_name created..Ok"
	wpconfig_task	
	fi
}

wpconfig_task()
# This block creates a wp-config.php file from the wp-config-sample.php file in the DocumentRoot/wordpress folder.
# wp-conf.php file is updated will the DB name and user-credentials.
# After completing the task, it calls the end_task().
{
	sudo cp /var/www/$domain_name/wordpress/wp-config-sample.php /var/www/$domain_name/wordpress/wp-config.php
	echo "wp-config file created from template"
	sudo sed -i 's/database_name_here/'$db_name'/g' /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/username_here/'$username'/g' /var/www/$domain_name/wordpress/wp-config.php
	sudo sed -i 's/password_here/'$password'/g' /var/www/$domain_name/wordpress/wp-config.php
	echo "wp-config.php file updated with MySql details"
	end_task
}

end_task()
# This block restarts the /etc/init.d/apache2 service and performs autoclean.
# After successfully completion it tells user to visit: http://$domain_name/wordpress/index.php"
{
	sudo /etc/init.d/apache2 restart 1> /dev/null;
	sudo apt-get autoclean 1> /dev/null;
	echo
	echo "All tasks Completed Successfully :-)"
	echo
	echo "Now Please visit: http://$domain_name/wordpress/index.php"
	echo
}

# Primary Block.
# This block checks the OS. If not Ubuntu, script exits.
# Also,this blocks checks for the Internet Connectivity. If not connected, it tells user to connect to internet & re-run the script.
# After checking it calls the package_check().

lsb_release -a | grep -i ubuntu > /dev/null
if [ ! $? = 0 ]; then
        echo "Script only meant for Ubuntu Systems, Exiting";exit 2;
else
echo "Checking Internet Connectivity.."
ping -W 1 -c 1 google.com 1> /dev/null;

if [ ! $? = 0 ]; then
        echo "Please connect to internet before running this script!"
        exit 1;
	else
        echo "Connected"
        echo

fi


package_check
fi

