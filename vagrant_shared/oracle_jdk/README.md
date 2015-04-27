# vagrant_shared/oracle_jdk

This directory contains a script for installing the Oracle JDK.

## install_jdk.sh

This script downloads and installs the Oracle JDK.

Because Oracle requires a license agreement to be accepted, the JDK cannot be
downloaded by Vagrant. Instead, the appropriate RPM file should be downloaded
manually, and placed in the "required" subdirectory. The particular Vagrant
build configurations will indicate which JDK file is expected.

The script expects the following environment variables to be populated:

 * JDK_RPM_FILE: The location of the Oracle JDK RPM file.

These environment variables are typically defined in the "vagrant_env_config.sh"
file of the Vagrant build configuration, which this script calls when running.
