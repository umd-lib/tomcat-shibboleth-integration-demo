tomcat-shibboleth-integration-demo
==================================

This repository contains two Vagrant configurations for demonstrating a
Shibboleth Identity Provider (IdP) working with a Shibboleth Service Provider
(SP) to protect a Tomcat web application.

## Vagrant Boxes

<p style="background-color: #fff8f7">
<strong>Warning:</strong><br>This document is not intended to show best practices
for setting up a production Shibboleth instance.
</p>
----

The demo-shibboleth-idp-sp-tomcat GitHub repository contains two Vagrant
configurations – one for a Shibboleth IdP, the other for a Shibboleth SP.

### Prerequisites
Both Vagrant configurations require the Java JDK. Download the jdk-7u79-linux-x79.rpm file from Oracle (http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
and placed in vm-setup/oracle_jdk/required/ directory.

### Shibboleth IdP Configuration

 * IP Address: 192.168.33.10
 * Apache v2.2.3
 * Tomcat v6.0.39
 * Java JDK v1.7.0_79
 * Shibboleth Identity Provider v2.3.8
 
### Shibboleth SP Configuration

 * IP Address: 192.168.33.20
 * Apache v2.2.3
 * Tomcat v7.0.42
 * Java JDK v1.7.0_79
 * Shibboleth v2.5.4
 
## IdP Setup

These instructions follow those provided in https://wiki.shibboleth.net/confluence/display/SHIB2/IdPSPLocalTestInstall
for setting up a Shibboleth IdP.

Apache HTTP, Tomcat, and the Shibboleth Identity Provider are downloaded as
part of the Vargrant setup. The following steps setup and configure the
software to serve as an IdP for the "simple" web application running in
Tomcat on the Shibboleth SP (192.168.33.20).

### Setup Shibboleth Identity Provider

1) Build and login to the vm-idp:

```
repo> cd vm-idp
repo> vagrant up
repo> vagrant ssh
```

2) Switch to the "shib" service user (password: "shib"):

```
idp> su - shib
```

3) Switch to /apps/shibboleth-identityprovider-2.3.8, run the install
script, and enter the values as shown (/apps/shibboleth-idp, 192.168.33.10, shib):

```
idp> cd /apps/shibboleth-identityprovider-2.3.8
idp> export JAVA_HOME=/usr/java/latest/
idp> ./install.sh
Buildfile: src/installer/resources/build.xml
install:
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Be sure you have read the installation/upgrade instructions on the Shibboleth website before proceeding.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Where should the Shibboleth Identity Provider software be installed? [/opt/shibboleth-idp]
/apps/shibboleth-idp
What is the fully qualified hostname of the Shibboleth Identity Provider server? [idp.example.org]
192.168.33.10
A keystore is about to be generated for you. Please enter a password that will be used to protect it.
shib
```

4) The "shib" service user has been added to the "sudoers" list, so edit the
/etc/httpd/conf/httpd.conf file:

```
idp> sudo vi /etc/httpd/conf/httpd.conf
```

and add the following line at the bottom of the file:

```
ProxyPass /idp/ ajp://localhost:8009/idp/
```

5) The Shibboleth IdP web application requires specific XML-related jar files
to run. Create an "endorsed" directory in /apps/tomcat/, and copy the jars
from the /apps/shibboleth-identityprovider-2.3.8/endorsed/ into it. The
/apps/tomcat/control script has been specially written to incorporate these
jars into the running Tomcat:

```
ipd> mkdir /apps/tomcat/endorsed
idp> cp /apps/shibboleth-identityprovider-2.3.8/endorsed/*.jar /apps/tomcat/endorsed
```

6) Modify AJP connector in /apps/tomcat/conf/server.xml  to allow Apache to
send usernames to the IdP:

```
idp> vi /apps/tomcat/conf/server.xml
```

Modify the AJP connector from:

```
    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />
```

to

```
    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443"
        enableLookups="false" request.tomcatAuthentication="false"
        address="127.0.0.1" />
```

7) Edit /etc/http/conf/httpd.conf

```
idp> sudo vi /etc/httpd/conf/httpd.conf
```

and add the following lines to the bottom of the file:

```
<Location /idp/Authn/RemoteUser>
  AuthType Basic
  AuthName "My Identity Provider"
  AuthUserFile /usr/local/idp/credentials/user.db
  require valid-user
</Location>
```

8) Create the /usr/local/idp/credentials/, and then use htpasswd to add some
users to it. These will be the users that are authorized to access the
resources protected by the SP:

```
idp> sudo mkdir /usr/local/idp/
idp> sudo chown shib:shib /usr/local/idp
idp> mkdir /usr/local/idp/credentials
idp> htpasswd -c /usr/local/idp/credentials/user.db myself
<Use the password "shib">
```

This creates a user named "myself" with a password of "shib".

9) Stop Apache Tomcat, and copy the idp.war file into the Tomcat webapps
directory:

```
idp> sudo /etc/init.d/httpd stop
idp> cd /apps/tomcat
idp> ./control stop
idp> cp /apps/shibboleth-idp/war/idp.war webapps
```

10) Edit the /apps/shibboleth-idp/conf/relying-party.xml file to configure the
IdP for use with the SP:

```
idp> vi /apps/shibboleth-idp/conf/relying-party.xml
```

This requires uncommenting the following MetadataProvider stanza, replacing the
"metadataURL" attribute with the SP address, and commenting out the
MetadataFilter stanzas, i.e. changing:

```
        <!-- Example metadata provider. -->
        <!-- Reads metadata from a URL and store a backup copy on the file system. -->
        <!-- Validates the signature of the metadata and filters out all by SP entities in order to save memory -->
        <!-- To use: fill in 'metadataURL' and 'backingFile' properties on MetadataResource element -->
        <!--
        <metadata:MetadataProvider id="URLMD" xsi:type="metadata:FileBackedHTTPMetadataProvider"
                          metadataURL="http://example.org/metadata.xml"
                          backingFile="/apps/shibboleth-idp/metadata/some-metadata.xml">
            <metadata:MetadataFilter xsi:type="metadata:ChainingFilter">
                <metadata:MetadataFilter xsi:type="metadata:RequiredValidUntil"
                                maxValidityInterval="P7D" />
                <metadata:MetadataFilter xsi:type="metadata:SignatureValidation"
                                trustEngineRef="shibboleth.MetadataTrustEngine"
                                requireSignedMetadata="true" />
                    <metadata:MetadataFilter xsi:type="metadata:EntityRoleWhiteList">
                    <metadata:RetainedRole>samlmd:SPSSODescriptor</metadata:RetainedRole>
                </metadata:MetadataFilter>
            </metadata:MetadataFilter>
        </metadata:MetadataProvider>
        -->
```

to

```
        <!-- Example metadata provider. -->
        <!-- Reads metadata from a URL and store a backup copy on the file system. -->
        <!-- Validates the signature of the metadata and filters out all by SP entities in order to save memory -->
        <!-- To use: fill in 'metadataURL' and 'backingFile' properties on MetadataResource element -->
        <metadata:MetadataProvider id="URLMD" xsi:type="metadata:FileBackedHTTPMetadataProvider"
                          metadataURL="http://192.168.33.20/Shibboleth.sso/Metadata"
                          backingFile="/apps/shibboleth-idp/metadata/some-metadata.xml">
<!--
            <metadata:MetadataFilter xsi:type="metadata:ChainingFilter">
                <metadata:MetadataFilter xsi:type="metadata:RequiredValidUntil"
                                maxValidityInterval="P7D" />
                <metadata:MetadataFilter xsi:type="metadata:SignatureValidation"
                                trustEngineRef="shibboleth.MetadataTrustEngine"
                                requireSignedMetadata="true" />
                    <metadata:MetadataFilter xsi:type="metadata:EntityRoleWhiteList">
                    <metadata:RetainedRole>samlmd:SPSSODescriptor</metadata:RetainedRole>
                </metadata:MetadataFilter>
            </metadata:MetadataFilter>
-->
        </metadata:MetadataProvider>
```

## Simple Web Application

The code checked out from the Git repository contains a simple web application
in the webapp/simple/ directory. Build it using the following steps:

```
repo> cd webapp/simple
repo> mvn clean package
```

This should create a "simple.war" file in the webapps/simple/target/ directory.
Copy the "simple.war" file into the vm-sp/ directory.

```
repo> cp target/simple.war ../../vm-sp/
```

## SP Setup

Apache HTTP, Tomcat, and Shibboleth are downloaded as part of the Vagrant
setup. The Apache server and Shibboleth were installed via the "yum" package
manager. See https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPLinuxRPMInstall
for information about installing Shibboleth via yum.

### Server Configuration

1) Build and login to the SP Vagrant box:

```
repo> cd vm-sp
repo> vagrant up
repo> vagrant ssh
```

2) Switch to the "shib" user (password: "shib"), and copy the "simple.war" file
into the Tomcat webapps directory:

```
sp> su - shib
sp> cd /apps/tomcat
sp> cp /vagrant/simple.war /apps/tomcat/webapps/
```

The Tomcat server is now running a simple "Hello World" web application at
http://192.168.33.20:8080/simple/

#### Verification steps:

a) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.20:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.20:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.20/simple/ - a "Not Found" error should be displayed.

### Configure Apache SSL

The following steps configure the SP to use SSL to respond to https, as well as
http URLs. See http://wiki.centos.org/HowTos/Https (alternative resource, with
slightly different instructions is Recipe 7.2 of Apache Cookbook, 2nd Edition)

3) Create self-signed certificate. Following the instructions in
http://wiki.centos.org/HowTos/Https:

```
sp> cd ~

sp> openssl genrsa -out ca.key 2048

sp> openssl req -new -key ca.key -out ca.csr
Country Name (2 letter code) [GB]:US
State or Province Name (full name) [Berkshire]:Maryland
Locality Name (eg, city) [Newbury]:College Park
Organization Name (eg, company) [My Company Ltd]:University of Maryland
Organizational Unit Name (eg, section) []:Library
Common Name (eg, your name or your server's hostname) []:192.168.33.20
Email Address []:
Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:

sp> openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt

sp> sudo cp ca.crt /etc/pki/tls/certs

sp> sudo cp ca.key /etc/pki/tls/private/ca.key

sp> sudo cp ca.csr /etc/pki/tls/private/ca.csr 
```

4) Edit /etc/httpd/conf.d/ssl.conf:

```
sp> sudo vi /etc/httpd/conf.d/ssl.conf
```

changing the "SSLCertificateFile" and "SSLCertificateKeyFile" entries to match
the locations of the key file and certificate created above.

```
SSLCertificateFile /etc/pki/tls/certs/ca.crt
SSLCertificateKeyFile /etc/pki/tls/private/ca.key
```

5) Restart Apache

```
sp> sudo /etc/init.d/httpd restart
```

#### Verification steps:

a) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.20:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.20:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.20/simple/ - a "Not Found" error should be displayed

e) Go to https://192.168.33.20:443/ - the "Apache 2 Test Page" should be
displayed (you will likely get one or more warnings about the connection
being untrusted – this is expected).

### Setup Reverse Proxy

6) Edit /etc/httpd/conf/httpd.conf

```
sp> sudo vi /etc/httpd/conf/httpd.conf
```

adding the following line (after the "LoadModule" section):

```
ProxyPass /simple ajp://localhost:8009/simple
```

(See Step 3 in https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPJavaInstall,
and also "Apache Integration with Tomcat" section in Chapter 5 of
[Tomcat: The Definitive Guide, 2nd Edition](http://proquest.safaribooksonline.com/book/programming/java/9780596101060)).

7) Restart Apache

```
sp> sudo /etc/init.d/httpd restart
```

#### Verification steps:

a) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.20:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.20:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.20/simple/ - a "Hello World" page should be displayed

e) Go to https://192.168.33.20:443/ - the "Apache 2 Test Page" should be
displayed (you will likely get one or more warnings about the connection
being untrusted – this is expected).

f) Go to https://192.168.33.20/simple/ - a "Hello World" page should be displayed (you will likely get one or more warnings about the connection being untrusted – this is expected).

### Shibboleth Setup

The following steps were derived from Step 4 in
https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPJavaInstall:

8) Edit /etc/httpd/conf/httpd.conf:

```
sp> sudo vi /etc/httpd/conf/httpd.conf
```

adding the following lines to the bottom of the file:

```
<Location /simple>
  AuthType shibboleth
  ShibRequestSetting requireSession 1
  require valid-user
</Location>
```

9) Restart Apache

```
sp> sudo /etc/init.d/httpd restart
```

10) Start the "shibd" Shibboleth daemon:

```
sp> sudo /sbin/service shibd start
```

#### Verification steps:

a) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.20:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.20:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.20/simple/ - Should get "shibsp::ConfigurationException"
page, indicating "No MetadataProvider available."

e) Go to https://192.168.33.20:443/ - the "Apache 2 Test Page" should be
displayed (you will likely get one or more warnings about the connection being
untrusted – this is expected).

f) Go to https://192.168.33.20/simple/ - Should get "shibsp::ConfigurationException"
page, indicating "No MetadataProvider available."

### Configuring Shibboleth

11) Stop Tomcat, Apache, and Shibboleth:

```
sp> cd /apps/tomcat/
sp> ./control stop
sp> sudo /etc/init.d/httpd stop
sp> sudo /sbin/service shibd stop
```

12) Edit /etc/shibboleth/shibboleth2.xml

```
sp> sudo vi /etc/shibboleth/shibboleth2.xml
```

and make the following changes:

a) Edit the "&lt;ApplicationDefaults>" stanza from:

```
    <ApplicationDefaults entityID="https://sp.example.org/shibboleth"
                         REMOTE_USER="eppn persistent-id targeted-id">
```

to

```
    <ApplicationDefaults entityID="https://192.168.33.20/shibboleth"
                         REMOTE_USER="eppn persistent-id targeted-id">
```

b) Edit the "&lt;SSO>" stanza from:

```
            <SSO entityID="https://idp.example.org/idp/shibboleth"
                 discoveryProtocol="SAMLDS" discoveryURL="https://ds.example.org/DS/WAYF">
              SAML2 SAML1
            </SSO>
```

to

```
            <SSO entityID="https://192.168.33.10/idp/shibboleth"
                 discoveryProtocol="SAMLDS" discoveryURL="https://ds.example.org/DS/WAYF">
              SAML2 SAML1
            </SSO>
```

c) Uncomment the stanza "&lt;MetadataProvider>" stanza, update it to point to
the IdP, and comment out the "&lt;MetadataFilter>" stanzas, i.e., change:

```
        <!-- Example of remotely supplied batch of signed metadata. -->
        <!--
        <MetadataProvider type="XML" uri="http://federation.org/federation-metadata.xml"
              backingFilePath="federation-metadata.xml" reloadInterval="7200">
            <MetadataFilter type="RequireValidUntil" maxValidityInterval="2419200"/>
            <MetadataFilter type="Signature" certificate="fedsigner.pem"/>
            <DiscoveryFilter type="Blacklist" matcher="EntityAttributes" trimTags="true"
              attributeName="http://macedir.org/entity-category"
              attributeNameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
              attributeValue="http://refeds.org/category/hide-from-discovery" />
        </MetadataProvider>
        -->
```

to

```
        <!-- Example of remotely supplied batch of signed metadata. -->
        <MetadataProvider type="XML" uri="http://192.168.33.10/idp/profile/Metadata/SAML"
              backingFilePath="federation-metadata.xml" reloadInterval="7200">
<!--
            <MetadataFilter type="RequireValidUntil" maxValidityInterval="2419200"/>
            <MetadataFilter type="Signature" certificate="fedsigner.pem"/>
-->
            <DiscoveryFilter type="Blacklist" matcher="EntityAttributes" trimTags="true"
              attributeName="http://macedir.org/entity-category"
              attributeNameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
              attributeValue="http://refeds.org/category/hide-from-discovery" />
        </MetadataProvider>
```

### Restart SP and IdP Services

12) Restart the services on the IdP and SP machines. The order is important,
and wait for each command to finish before running the next one:

```
idp> cd /apps/tomcat/
idp> sudo /etc/init.d/httpd start

sp> cd /apps/tomcat/
sp> ./control start
sp> sudo /etc/init.d/httpd start

sp> sudo /sbin/service shibd start

idp> ./control start

sp> sudo /sbin/service shibd restart
```
----
<p style="background-color: #fffdf6">
<strong>Note:</strong> 
<br>
The order above is important because of the way the Shibboleth metadata is
being passed between the two servers. The "idp" web application on the IdP
server needs to be able to retrieve the metadata from the Shibboleth daemon on
the SP, so the shibd process must be started, before the IdP Tomcat. However,
when the shibd process runs, it want to retrieve a "http://192.168.33.10/idp/profile/Metadata/SAML"
file from the IdP.
<br>
<br>
Starting the shibd first, then starting Tomcat on the IdP, allows the IdP to
retrieve the necessary metadata from shibd. Then restarting the shibd process
allows the SP to retrieve the necessary data from the IdP.
<br>
<br>
All this is likely necessary because the shibd process on the SP is using a
MetadataGenerator to construct the metadata file to send to the IdP. According
to the Shibboleth documentation, the MetadataGenerator should not be used In a
production environment.
</p>
----

#### Verification steps:

a) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.20:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.20:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.20/simple/ - Should be prompted for a login. After
login, the "Hello World" page should be displayed (you will likely get one or
more warnings about the connection being untrusted – this is expected).

e) Go to https://192.168.33.20:443/ - the "Apache 2 Test Page" should be
displayed (you will likely get one or more warnings about the connection
being untrusted – this is expected).

f) Go to https://192.168.33.20/simple/ - The result will depend on the prior
sequence of steps. If you have already performed Step d (http://192.168.33.20/simple/)
in the same browser (without restarting the browser), the "Hello World" page
should be displayed, without requesting a login (there may be warnings about
untrusted connections). If you've restarted the browser, and go directly to
https://192.168.33.20/simple/, then you will be asked to login (again, possibly
with warnings about untrusted connections), and then a Shibboleth error
"Error Message: No peer endpoint available to which to send SAML response"
will be displayed.

### Troubleshooting

If things don't seem to be working, here's some things to look for:

1) Is the "idp" web application running on Tomcat?

There are several ways to check:

 * Point a web browser at the idp web application: https://192.168.33.10/idp/shibboleth.
   If you get a resource not found error, the idp web application has not started.

 * In the /apps/tomcat/logs/catalina-daemon.log, look for errors like:
 ```
INFO: Deploying web application archive idp.war
Apr 23, 2015 5:13:01 AM org.apache.catalina.core.StandardContext start
SEVERE: Error listenerStart
Apr 23, 2015 5:13:01 AM org.apache.catalina.core.StandardContext start
SEVERE: Context [/idp] startup failed due to previous errors
 ```
 
* You can also configure the Tomcat server to allow access to the Tomcat Manager
  console, and determine if the idp web application is running.

If the idp web application won't start, look in the logs at
/apps/shibboleth-idp/logs/, particularly the "idp-process.log"

----

### Tying up the Loose Ends

There are several issues with the above setup:

1) It is possible to access the protected resource without logging in by going
directly to it via port 8080.

2) Using "https" may result in a Shibboleth error.

3) Shibboleth is not passing any useful attributes to the protected resource.

#### Blocking port 8080 access to the protected resource

Following the advice in Chapter 6 of [O'Reilly's Tomcat: The Definitive Guide, 2nd Edition](http://proquest.safaribooksonline.com/book/programming/java/9780596101060),
block access to port 8080 at the firewall by running the following iptables
commands on the SP machine:

```
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8080 -d 192.168.33.20 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8009 -d 192.168.33.20 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8443 -d 192.168.33.20 -j DROP
sp> sudo /sbin/service iptables save
```

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login
sessions).

b) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

c) Go to http://192.168.33.20:8080/ - the browser should wait, and then timeout.

d) Go to http://192.168.33.20/simple/ - Should be prompted for a login. After
login, the "Hello World" page should be displayed (you will likely get one or
more warnings about the connection being untrusted – this is expected).

e) Go to http://192.168.33.20:8080/simple/ - the browser should wait, and then
timeout.

#### Fixing https handling

When accessing https://192.168.33.20/simple, the browser may display a
Shibboleth error "No peer endpoint available to which to send SAML response".
There are two issues that need to be corrected.

The first issue is that the Java runtime on the IdP does not recognize the
certificate used by the SP as a valid certificate, because it is self-signed.
This should not be an issue with "real" certificates, but in this case, we need
to add the certificate to the Java keystore. To do this:

1) Copy the /etc/pki/tls/certs/ca.crt created in Step 3 of the SP setup from
the SP to the IdP. (Easiest way is to copy it to the /vagrant directory on the
SP machine, then on the host machine, copy it into the vm-idp directory, where
it will be available in the /vagrant directory on the IdP). The following steps
assume the "ca.crt" file is in the /vagrant directory on the IdP machine.

2) Using http://azure.microsoft.com/en-us/documentation/articles/java-add-certificate-ca-store/
as a guide, run the following commands:

```
idp> cd /usr/java/latest/jre/lib/security
idp> sudo keytool -keystore cacerts -importcert -alias test_shib_sp -file /vagrant/ca.crt
The keystore password is "changeit"
...
Trust this certificate? [no]:  yes
```

3) On the SP edit the /etc/shibboleth/shibboleth2.xml:

```
sp> sudo vi /etc/shibboleth/shibboleth2.xml
```

changing the line:

```
             <Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>
```

to

```
             <Handler type="MetadataGenerator" Location="/Metadata" https="true" signing="false" />
```

This will cause the metadata file sent by the SP to the IdP to include https
endpoints. See https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPHandler.

4) Restart the Tomcat and Apache services on the IdP machine, and the Tomcat,
Apache, and shibd daemon on the SP machine.

```
idp> cd /apps/tomcat
idp> ./control stop; sudo /etc/init.d/httpd stop

sp> cd /apps/tomcat
sp> ./control stop; sudo /etc/init.d/httpd stop; sudo /sbin/service shibd stop

idp> cd /apps/tomcat/
idp> sudo /etc/init.d/httpd start

sp> cd /apps/tomcat/
sp> ./control start
sp> sudo /etc/init.d/httpd start

sp> sudo /sbin/service shibd start

idp> ./control start

sp> sudo /sbin/service shibd restart
```

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login
sessions).

b) Go to http://192.168.33.20/ - the "Apache 2 Test Page" should be displayed.

c) Go to http://192.168.33.20:8080/ - the browser should wait, and then timeout.

d) Go to https://192.168.33.20/simple/ - Should be prompted for a login. After
login, the "Hello World" page should be displayed (you will likely get one or
more warnings about the connection being untrusted – this is expected).

e) Go to https://192.168.33.20:8080/simple/ - the browser should wait, and then
timeout.

#### Passing Attributes

The Shibboleth IdP can pass attributes containing information about the user
logging in to the SP.

Both the IdP and SP must be configured – the IdP to determine how attributes
are defined and what attributes are available to a particular SP, the SP to
define what attributes are accepted and what they are named.

Normally attributes about a user are retrieved from a data source such as LDAP
or a database. For this demonstration, we will just be returning static
information not tied to any particular user.

##### IdP Setup

Following the steps in https://wiki.shibboleth.net/confluence/display/SHIB2/IdPSPLocalTestInstall
we will be returning two static attributes:

 * eduPersonAffiliation: Contains the value "member"
 * eduPersonEntitlement: Contains the values "urn:example.org:entitlement:entitlement1" and "urn:mace:dir:entitlement:common-lib-terms"

1) Edit the /apps/shibboleth-idp/conf/attribute-resolver.xml file:

```
idp> sudo vi /apps/shibboleth-idp/conf/attribute-resolver.xml
```
making the following changes:

a) Uncomment the "&lt;resolver:AttributeDefinition ... id="eduPersonAffiliation" ...">"
and "&lt;resolver:AttributeDefinition ... id="eduPersonEntitlement ...">" stanzas
in the "Schema: eduPerson attributes" section (move the "<!–" to after the
"eduPersonEntitlement" stanza). In each stanza, replace the
"&lt;resolver:Dependency ref="myLDAP" />" entry with "&lt;resolver:Dependency ref="staticAttributes" />.
When completed, the stanzas should look like:

```
    <!-- Schema: eduPerson attributes -->
    <resolver:AttributeDefinition xsi:type="ad:Simple" id="eduPersonAffiliation" sourceAttributeID="eduPersonAffiliation">
        <resolver:Dependency ref="staticAttributes" />
        <resolver:AttributeEncoder xsi:type="enc:SAML1String" name="urn:mace:dir:attribute-def:eduPersonAffiliation" />
        <resolver:AttributeEncoder xsi:type="enc:SAML2String" name="urn:oid:1.3.6.1.4.1.5923.1.1.1.1" friendlyName="eduPersonAffiliation" />
    </resolver:AttributeDefinition>

    <resolver:AttributeDefinition xsi:type="ad:Simple" id="eduPersonEntitlement" sourceAttributeID="eduPersonEntitlement">
        <resolver:Dependency ref="staticAttributes" />
        <resolver:AttributeEncoder xsi:type="enc:SAML1String" name="urn:mace:dir:attribute-def:eduPersonEntitlement" />
        <resolver:AttributeEncoder xsi:type="enc:SAML2String" name="urn:oid:1.3.6.1.4.1.5923.1.1.1.7" friendlyName="eduPersonEntitlement" />
    </resolver:AttributeDefinition>
```

b) In the "Data Connectors" section of the file, uncomment the "Example Static Connector".
Notice that it is already configured with values for the "eduPersonAffiliation"
and "eduPersonEntitlement" attributes.

2) Edit the /apps/shibboleth-idp/conf/attribute-filter.xml file:

```
idp> sudo vi /apps/shibboleth-idp/conf/attribute-filter.xml
```

uncommenting the "&lt;afp:AttributeFilterPolicy>" stanza (the portal example)
at the end of the file and changing it to:

```
    <afp:AttributeFilterPolicy>
        <afp:PolicyRequirementRule xsi:type="basic:AttributeRequesterString" value="https://192.168.33.20/shibboleth" />
        <afp:AttributeRule attributeID="eduPersonAffiliation">
            <afp:PermitValueRule xsi:type="basic:ANY" />
        </afp:AttributeRule>
        <afp:AttributeRule attributeID="eduPersonEntitlement">
            <afp:PermitValueRule xsi:type="basic:ANY" />
        </afp:AttributeRule>
    </afp:AttributeFilterPolicy>
```

##### SP Setup

1) Edit the /etc/shibboleth/shibboleth2.xml file:

```
sp> sudo vi /etc/shibboleth/shibboleth2.xml
```

adding an "attributePrefix="AJP_"" attribute to the &lt;ApplicationDefaults>
stanza, i.e.:

```
    <ApplicationDefaults entityID="https://192.168.33.20/shibboleth"
                         REMOTE_USER="eppn persistent-id targeted-id" signing="false"
                         encryption="false" attributePrefix="AJP_">
```

This is necessary for the AJP protocol used by Tomcat.

No changes are needed on the SP to support the two attributes being used in
this example. For other attributes, the /etc/shibboleth/attribute-map.xml might
need to be edited to map particular attributes to particular names for use by
the Java servlet.

2) Restart the Tomcat and Apache services on the IdP machine, and the Tomcat,
Apache, and shibd daemon on the SP machine.

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login sessions).

b) Go to https://192.168.33.20/simple/ - After logging in the page should
display the following two parameters, along with some others:

 * entitlement = urn:mace:dir:entitlement:common-lib-terms;urn:example.org:entitlement:entitlement1
 * unscoped-affiliation = member

----

### Troubleshooting Attributes

#### Attributes on the IdP

The Shibboleth IdP application has a "aacli.sh" script to return what attributes
will be sent to a particular SP for a particular user. 
ee https://wiki.shibboleth.net/confluence/display/SHIB2/AACLI for more information.

For some reason, the Shibboleth IdP doesn't include the servlet-api.jar, so the
"aacli.sh" script doesn't work out of the box (it gives ClassNotFoundExceptions
when you try to run it). To fix this, simply copy the servlet-api.jar file into
the "lib" directory, i.e.:

```
> cp /apps/tomcat/lib/servlet-api.jar /apps/shibboleth-idp/lib/
```

To see what attributes will be sent to the SP for the "myself" user, run the
following commands:

```
> /apps/shibboleth-idp/bin/aacli.sh --configDir /apps/shibboleth-idp/conf --principal myself --requester https://192.168.33.20/shibboleth
```

This will print out XML containing the attributes sent to the SP.

#### Attributes on the SP

1) On the SP, edit the /etc/shibboleth/shibboleth2.xml, changing the
"showAttributeValues" flag in the Sessions handler to "true", i.e.:

```
<Sessions ..>
...
  <!-- Session diagnostic service. -->
  <Handler type="Session" Location="/Session" showAttributeValues="true"/>
...
</Sessions>
```

2) Go to the protected resource https://192.168.33.20/simple. After logging in,
(and dealing with any warnings about untrusted connections) go to
https://192.168.33.20/Shibboleth.sso/Session. Information about the
session, including the attributes, will be displayed.

----

## License

These files are provided under the CC0 1.0 Universal license (http://creativecommons.org/publicdomain/zero/1.0/).
