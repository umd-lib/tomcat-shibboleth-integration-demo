# vagrant_shared/tomcat

This directory contains a script for installing Apache Tomcat.

## tomcat_setup.sh

This script downloads and installs Apache Tomcat.

The script expects the following environment variables to be populated:

 * APACHE_TOMCAT_URL: The URL of the location to download Apache Tomcat from.
 * APACHE_TOMCAT_FILENAME: The filename (without of the path) of the downloaded
  file.
 * APACHE_TOMCAT_DIR: The name of the directory (without of the path) of the 
  directory to install Apache Tomcat to.
 * APPS_DIR: The base directory to install Tomcat to.
 * SERVICE_USER_ACCOUNT_NAME: The name of the service account to run Tomcat
  under. Used to replace the "SED_SERVICE_USER_ACCOUNT_NAME" in the control
  script.

These environment variables are typically defined in the "vagrant_env_config.sh"
file of the Vagrant build configuration, which this script calls when running.