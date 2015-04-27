#!/bin/bash

# Note: This script MUST be run as the service user.

# Configure the environment
source /vagrant/vagrant_env_config.sh

# Install Shibboleth IdP
echo --- Installing Shibboleth IdP ---
cd /apps
curl -O http://shibboleth.net/downloads/identity-provider/2.3.8/shibboleth-identityprovider-2.3.8-bin.zip
unzip shibboleth-identityprovider-2.3.8-bin.zip
#cd identityprovider

echo -- Starting Tomcat ---
$APACHE_TOMCAT_ALIAS_DIR/bin/daemon.sh --tomcat-user $SERVICE_USER_ACCOUNT_NAME --java-home /usr/java/latest start

echo --- Done ---
