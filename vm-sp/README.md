# sp-tomcat-shibboleth-integration-demo

- Operating System: CentOS 5.10 64-bit
- VM Memory: 2 gigabytes
- Default IP Address: 192.168.33.20 (Private Network)

Sets up a demonstration SP for testing Tomcat integration with Shibboleth.
See https://github.com/dsteelma-umd/tomcat-shibboleth-integration-demo/ for setup instructions.

## Required Components

The following components are required for Vagrant to build the virtual machine.
While normally Vagrant can download the necessary components, the following
components are not freely downloadable, typically requiring the acceptance of
a license agreement. Please download the components and place them in the
"required" subdirectory.

|Component|Filename|Default directory|Notes|
|---------|--------|-----------------|-----|
|Oracle JDK|jdk-7u79-linux-x64.rpm|vm-setup/oracle_jdk/required|Typically downloaded from Oracle (http://www.oracle.com/technetwork/java/javase/downloads/index.html)|

The exact path and filename for the components are specified in
[vagrant_env_config.sh](vagrant_env_config.sh).

## Installed Components
This Vagrant build downloads and installs the following:

|Component|Version|
|---------|-------|
|Apache Tomcat|v7.0.42|

## Configuration Information
This build places uses the following directory structure on the guest machine:

- /apps/tomcat/ - Symbolic link to the actual Tomcat directory, which by default
is placed in /apps/apache-tomcat-[version] 

A "shib" service user is created during configuration, and is used to run
Apache Tomcat.

To access the "shib" service account:

```
> su - shib
Password: [Password]
```
The default password is "shib".

##### IP Address
The default IP address is 192.168.33.20.

##### Memory
The default amount of memory provided to the virtual machine can be changed in
the [VagrantFile](VagrantFile).

#### Java
See the "Java" section in [vagrant_env_config.sh](vagrant_env_config.sh).

#### Apache Tomcat
See the "Apache Tomcat" section in
[vagrant_env_config.sh](vagrant_env_config.sh).

#### Service User
The default username and password for the service user (default "shib") can be
changed in [vagrant_env_config.sh](vagrant_env_config.sh).
