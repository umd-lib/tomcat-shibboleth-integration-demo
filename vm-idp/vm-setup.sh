#!/bin/bash

# This script downloads, installs, and configures the necessary components
# setting up the virtual machine.
#
# Note: This script MUST be run as the "vagrant" user.

# Configure the environment
source /vagrant/vagrant_env_config.sh

# Overwrite default Yum repos list with custom one using vault.centos.org
# CentOS 5.10 has been end-of-lifed, so can no longer use default repos
cp /vagrant_shared/vm-setup/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

# Install expect
echo --- Installing expect ---
yum -y install expect

# Setup the "service" user account
bash /vagrant/vm-setup/service_user_setup.sh

# Create apps directory
# Create APPS_DIR, if needed.
if [ ! -d "$APPS_DIR" ]; then 
  mkdir $APPS_DIR
fi

# Make apps directory owned by the service account
chown --recursive $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_NAME $APPS_DIR

# Add service account to sudoers
echo "$SERVICE_USER_ACCOUNT_NAME           ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# Setup Apache Tomcat
bash /vagrant/vm-setup/tomcat/tomcat_setup.sh

# Install Apache
echo --- Installing Apache ---
yum -y install httpd

# Install SSL
echo --- Installing SSL ---
yum -y install mod_ssl openssl

# Start Apache
echo --- Starting Apache ---
/etc/init.d/httpd start

# Install Git
echo --- Installing Git ---
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
sudo yum -y install git

# Run the rest of the script as the service user
sudo -i -u $SERVICE_USER_ACCOUNT_NAME bash /vagrant/vm-setup/run_as_service_user.sh
