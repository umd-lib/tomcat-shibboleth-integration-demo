#!/bin/bash

# Script for downloading, installing, and configuring Apache Tomcat.

# Configure the environment
source /vagrant/vagrant_env_config.sh

echo -- Apache Tomcat Install ---

# Use default service account of "ole" if a service account is not specified.
#if [ -n ${SERVICE_USER_ACCOUNT_NAME} ]; then
#  echo SERVICE_USER_ACCOUNT_NAME not defined.
#  exit 1
#fi
: ${SERVICE_USER_ACCOUNT_NAME:?"SERVICE_USER_ACCOUNT_NAME not defined."; exit 1}

# Retrieve Apache Tomcat
echo -- Retrieving Apache Tomcat ---
wget --quiet $APACHE_TOMCAT_URL

# Install Apache Tomcat
echo --- Installing Apache Tomcat ---

# Create APPS_DIR, if needed.
if [ ! -d "$APPS_DIR" ]; then 
  mkdir $APPS_DIR
fi

cp /home/vagrant/$APACHE_TOMCAT_FILENAME $APPS_DIR
cd $APPS_DIR
tar -xvzf $APACHE_TOMCAT_FILENAME > /dev/null 2>&1
rm $APACHE_TOMCAT_FILENAME
chown --recursive $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_NAME $APACHE_TOMCAT_DIR
ln -s $APACHE_TOMCAT_DIR $APACHE_TOMCAT_ALIAS_DIR

# Build Apache Tomcat jsvc
cd $APACHE_TOMCAT_ALIAS_DIR/bin
tar -xvzf commons-daemon-native.tar.gz
cd $APACHE_TOMCAT_COMMON_DAEMON_SRC_DIR
export JAVA_HOME=/usr/java/latest
cd unix
./configure
make
mv jsvc $APACHE_TOMCAT_ALIAS_DIR/bin/
cd $APACHE_TOMCAT_ALIAS_DIR/bin/
rm -rf $APACHE_TOMCAT_COMMON_DAEMON_SRC_DIR
chown -R $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_NAME jsvc
chmod 544 jsvc

# Create setenv.sh script for setting Tomcat defaults
cat <<EOT  >> setenv.sh
CATALINA_HOME=$APACHE_TOMCAT_ALIAS_DIR
# Java needs more memory to run Kuali OLE code
JAVA_OPTS="-Xms1024m -Xmx2048m -XX:MaxPermSize=512m"
# To enable Eclipse debugger, uncomment the following line
#JAVA_OPTS="\$JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"
export CATALINA_HOME JAVA_OPTS
EOT
chown -R $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_NAME setenv.sh
chmod 544 setenv.sh

# Create control script for running Tomcat
cd $APACHE_TOMCAT_ALIAS_DIR
cp /vagrant/vm-setup/tomcat/control $APACHE_TOMCAT_ALIAS_DIR/control
# Replace SERVICE_USER_ACCOUNT_NAME in control script with contents of
# environment variable
sed -i "s/SED_SERVICE_USER_ACCOUNT_NAME/$SERVICE_USER_ACCOUNT_NAME/g" $APACHE_TOMCAT_ALIAS_DIR/control
chown -R $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_NAME $APACHE_TOMCAT_ALIAS_DIR/control
chmod 544 control

