#!/bin/bash

# FlaskInstall by Nick Tikhonov
# installs Apache 2 with Flask on a fresh Ubuntu server

echo "------ FlaskInstall by Nick Tikhonov ------"
echo "NOTE: Please make sure you are running this on Ubuntu 13+"
echo "This script will install + configure:"
echo " -- Apache 2"
echo " -- Apache WSGI"
echo " -- MySQL (will configure app database)"
echo " -- Flask (will configure WSGI and create template project w. database access)"
echo "Please type anything to begin installation!"
read continueinstallation

echo "------------------------"
echo "Please enter a MySQL root password (this will be printed at the end):"
read mysql_password

echo "------------------------"
echo "Application Name (e.g. 'FlaskApp' or 'WebsiteApp' or 'HelloWorldApp'): "
read appname

echo "------------------------"
echo "Domain name or server IP address (e.g. mywebsite.net): "
read hostaddress

echo "------------------------"
echo "Admin email address (e.g. admin@mywebsite.net): "
read adminemail

echo "------------------------"
echo "Please enter a secret key (a long & secure string of characters): "
read secretkey

# Start by installing Apache 
sudo apt-get update
sudo apt-get install apache2
sudo apt-get install libapache2-mod-wsgi python-dev
sudo apt-get install libmysqlclient-dev
sudo a2enmod wsgi 

# Install MySQL Server

echo "mysql-server-5.5 mysql-server/root_password password $mysql_password" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_password" | debconf-set-selections
sudo apt-get -y install mysql-server

# Create the template flask app
cd /var/www 

#make MySQL DB for the app
mysql -u root -p$mysql_password -e "create database $appname"

sudo mkdir $appname
cd $appname
sudo mkdir $appname 
cd $appname
sudo mkdir static templates

cat <<EOF > __init__.py
from flask import Flask
from flaskext.mysql import MySQL

mysql = MySQL()
app = Flask(__name__)

app.config['MYSQL_DATABASE_USER'] = 'root'
app.config['MYSQL_DATABASE_PASSWORD'] = '$mysql_password'
app.config['MYSQL_DATABASE_DB'] = '$appname'
app.config['MYSQL_DATABASE_HOST'] = 'localhost'
mysql.init_app(app)

def query(sql_string):
	cursor = mysql.connect().cursor()
	cursor.execute(sql_string)
	results = cursor.fetchall()
	cursor.close()
	return results

@app.route("/")
def hello():
	return "Hello World! FlaskInstall ran correctly!"
if __name__ == "__main__":
	app.run()
EOF

# Install Flask, Flask-MySQL
sudo apt-get install python-pip
sudo pip install Flask
sudo pip install flask-mysql

cat <<EOF > /etc/apache2/sites-available/$appname.conf
<VirtualHost *:80>
		ServerName $hostaddress
		ServerAdmin $adminemail
		WSGIScriptAlias / /var/www/$appname/$appname.wsgi
		<Directory /var/www/$appname/$appname/>
			Order allow,deny
			Allow from all
		</Directory>
		Alias /static /var/www/$appname/$appname/static
		<Directory /var/www/$appname/$appname/static/>
			Order allow,deny
			Allow from all
		</Directory>
		ErrorLog ${APACHE_LOG_DIR}/error.log
		LogLevel warn
		CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2ensite $appname

cat <<EOF > /var/www/$appname/$appname.wsgi
#!/usr/bin/python
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/$appname/")

from $appname import app as application
application.secret_key = '$secretkey'
EOF

sudo service apache2 restart

echo "Done! Please visit $hostaddress to check that everything works"
echo "|---------------------------------"
echo "| App name       : $appname       "
echo "| Address        : $hostaddress   "
echo "| Secret Key     : $secretkey     "
echo "| MySQL password : $mysql_password"
echo "|---------------------------------"