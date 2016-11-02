#!/bin/bash

# This script contains the environment variables for the Vagrant
# configuration.
#
# Each script that requires access to these variables will "source"
# this file.

#---------------------
# System configuration
#---------------------
# APPS_DIR: Directory where downloaded applications are installed
APPS_DIR=/apps

#-----------------
# shib User Account
#-----------------
SERVICE_USER_ACCOUNT_NAME=shib
SERVICE_USER_ACCOUNT_PASSWORD=shib

#-----
# Java
#-----
JDK_RPM_FILE=/vagrant_shared/oracle_jdk/required/jdk-7u79-linux-x64.rpm
JAVA_HOME_DIR=/usr/java/jdk1.7.0_79

#--------------
# Apache Tomcat
#--------------
# APACHE_TOMCAT_URL: URL to download Apache Tomcat from.
APACHE_TOMCAT_URL=http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.39/bin/apache-tomcat-6.0.39.tar.gz
APACHE_TOMCAT_FILENAME=${APACHE_TOMCAT_URL##*/}
APACHE_TOMCAT_DIR=${APACHE_TOMCAT_FILENAME%.tar.gz}

# APACHE_TOMCAT_COMMON_DAEMON_SRC_DIR: Name of the directory inside the
# Apache Tomcat download for the Apache Commons Daemon source.
APACHE_TOMCAT_COMMON_DAEMON_SRC_DIR=commons-daemon-1.0.15-native-src

# APACHE_TOMCAT_ALIAS_DIR - Location of alias directory for accessing Tomcat
APACHE_TOMCAT_ALIAS_DIR=$APPS_DIR/tomcat
