#!/bin/bash

# Configure the environment
source /vagrant/vagrant_env_config.sh

# Check for required files.
if [ -f $JDK_RPM_FILE ];
then
   echo JDK RPM found at: $JDK_RPM_FILE
else
   >&2 echo JDK RPM file not found at at:
   >&2 echo "  $JDK_RPM_FILE"
   >&2 echo Please download a JDK RPM, and place in the
   >&2 echo "vm-setup/oracle_jdk/required/" directory, or
   >&2 echo modify the JDK_RPM_FILE environment variable in
   >&2 echo vagrant_env_config.sh to point to the correct RPM.
   exit 1;
fi

# Install the JDK, suppressing the output, as it is just noise in Vagrant output.
rpm -Uvh $JDK_RPM_FILE > /dev/null 2>&1
