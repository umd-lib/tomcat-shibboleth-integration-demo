#!/bin/bash

# Script for creating and configuring the service user account

# Configure the environment
source /vagrant/vagrant_env_config.sh

# Create service user
echo --- Creating service user account ---
/usr/sbin/useradd $SERVICE_USER_ACCOUNT_NAME
echo --- Setting service user password ---
echo $SERVICE_USER_ACCOUNT_NAME:$SERVICE_USER_ACCOUNT_PASSWORD | /usr/sbin/chpasswd

# Configure service user
# Note: $ in environment variables need to be escaped with a backslash
echo --- Configuring service user ---
cat <<EOT >> /home/$SERVICE_USER_ACCOUNT_NAME/.bashrc
umask 002

export JAVA_HOME=$JAVA_HOME_DIR

PATH=\${JAVA_HOME}/bin:\${PATH}
EOT