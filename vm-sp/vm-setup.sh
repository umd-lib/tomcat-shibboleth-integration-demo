#!/bin/bash

# This script downloads, installs, and configures the necessary components
# setting up the virtual machine.
#
# Note: This script MUST be run as the "vagrant" user.

# Configure the environment
source /vagrant/vagrant_env_config.sh

# Install expect
echo --- Installing expect ---
yum -y install expect

# Setup the "service" user account
bash /vagrant/vm-sp/vm-setup/service_user_setup.sh

# Add service account to sudoers
echo "$SERVICE_USER_ACCOUNT_NAME           ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# Setup Apache Tomcat
bash /vagrant/vm-sp/vm-setup/tomcat/tomcat_setup.sh

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

# Install Shibboleth
echo --- Installing Shibboleth ---
sudo wget --quiet http://download.opensuse.org/repositories/security://shibboleth/CentOS_5/security:shibboleth.repo -O /etc/yum.repos.d/shibboleth.repo
sudo yum -y install shibboleth.x86_64

# Run the rest of the script as the service user
sudo -i -u $SERVICE_USER_ACCOUNT_NAME bash /vagrant/vm-sp/vm-setup/run_as_service_user.sh
