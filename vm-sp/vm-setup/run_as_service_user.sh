#!/bin/bash

# Note: This script MUST be run as the service user.

# Configure the environment
source /vagrant/vagrant_env_config.sh

echo -- Starting Tomcat ---
$APACHE_TOMCAT_ALIAS_DIR/bin/daemon.sh --tomcat-user $SERVICE_USER_ACCOUNT_NAME --java-home /usr/java/latest start

echo --- Done ---
