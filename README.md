tomcat-shibboleth-integration-demo
==================================
## Branch: multiple-sp-endpoints

This branch demonstrates having an IdP configuration that responds to multiple SP servers (for example, a "sp-dev" and a "sp-production".

## Vagrant Boxes

<p style="background-color: #fff8f7">
<strong>Warning:</strong><br>This document is not intended to show best practices
for setting up a production Shibboleth instance.
</p>
----

This branch contains a multi-machine Vagrantfile, which sets up three machines:

 * A Shibboleth IdP
 * A "dev" Shibboleth SP
 * A "production" Shibboleth SP
 
The metadata for the IdP will list both the "dev" and "production" SP machines as AssertionConsumerService. The "dev" and "production" SP will share the same Shibboleth private key, in order to enable them both to decrypt the response from the IdP.

### Prerequisites

The Vagrant configurations require the Java JDK. Download the jdk-7u79-linux-x64.rpm file from Oracle (http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
and placed in vagrant_shared/oracle_jdk/required/ directory.

### Shibboleth IdP Configuration

 * IP Address: 192.168.33.110
 * Apache v2.2.3
 * Tomcat v6.0.39
 * Java JDK v1.7.0_79
 * Shibboleth Identity Provider v2.3.8
 
### Shibboleth sp-dev Configuration

 * IP Address: 192.168.33.120
 * Apache v2.2.3
 * Tomcat v7.0.42
 * Java JDK v1.7.0_79
 * Shibboleth v2.5.4
 
### Shibboleth sp-production Configuration

 * IP Address: 192.168.33.130
 * Apache v2.2.3
 * Tomcat v7.0.42
 * Java JDK v1.7.0_79
 * Shibboleth v2.5.4

### Service Account 

Each machine has a "shib" service user that is created during configuration, and is used to run Apache Tomcat.

To access the "shib" service account:

```
> su - shib
Password: [Password]
```
The default password is "shib".

The default username and password for the service user (default "shib") can be
changed in [vagrant_env_config.sh](vagrant_env_config.sh).
 
## Build the Vagrant machines

All three machines are defined in the Vagrantfile, so they can all be built with the following command:

```
repo> vagrant up
```

This process may take 10-20 minutes.
 
## Simple Web Application

The code checked out from the Git repository contains a simple web application
in the webapp/simple/ directory. Build it using the following steps:

```
repo> cd webapp/simple
repo> mvn clean package
```

This should create a "simple.war" file in the webapps/simple/target/ directory.
Copy the "simple.war" file into the root directory (so it is available to the VMs in the "/vagrant" directory.

```
repo> cp target/simple.war ../..
repo> cd ../..
```

## sp-dev Setup

Apache HTTP, Tomcat, and Shibboleth are downloaded as part of the Vagrant
setup. The Apache server and Shibboleth were installed via the "yum" package
manager. See https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPLinuxRPMInstall
for information about installing Shibboleth via yum.

### Server Configuration

For the "sp-dev" machine, do the following:

1) Login to the "sp-dev" Vagrant box:


```
repo> vagrant ssh sp-dev
```

2) Switch to the "shib" user (password: "shib"), and copy the "simple.war" file
into the Tomcat webapps directory:

```
sp> su - shib
sp> cd /apps/tomcat
sp> cp /vagrant/simple.war /apps/tomcat/webapps/
```

### Configure Apache SSL

The following steps configure the SP to use SSL to respond to https, as well as
http URLs. See http://wiki.centos.org/HowTos/Https (alternative resource, with
slightly different instructions is Recipe 7.2 of Apache Cookbook, 2nd Edition)

3) Create self-signed certificate. Following the instructions in
http://wiki.centos.org/HowTos/Https:

**For sp-production "Common Name" parameter should be adjusted**

```
sp> cd ~

sp> openssl genrsa -out ca.key 2048

sp> openssl req -new -key ca.key -out ca.csr
Country Name (2 letter code) [GB]:US
State or Province Name (full name) [Berkshire]:Maryland
Locality Name (eg, city) [Newbury]:College Park
Organization Name (eg, company) [My Company Ltd]:University of Maryland
Organizational Unit Name (eg, section) []:Library
Common Name (eg, your name or your server's hostname) []:192.168.33.120
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

### Setup Reverse Proxy and Shibboleth

5) Edit /etc/httpd/conf/httpd.conf

```
sp> sudo vi /etc/httpd/conf/httpd.conf
```

adding the following lines to the end of the file

```
ProxyPass /simple ajp://localhost:8009/simple

<Location /simple>
  AuthType shibboleth
  ShibRequestSetting requireSession 1
  require valid-user
</Location>
```

### Configuring Shibboleth

6) Stop Tomcat, Apache, and Shibboleth:

```
sp> cd /apps/tomcat/
sp> ./control stop
sp> sudo /etc/init.d/httpd stop
sp> sudo /sbin/service shibd stop
```

7) Edit /etc/shibboleth/shibboleth2.xml

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
    <ApplicationDefaults entityID="https://example-app.lib.umd.edu/shibboleth"
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
            <SSO entityID="https://192.168.33.110/idp/shibboleth"
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
        <MetadataProvider type="XML" uri="http://192.168.33.110/idp/profile/Metadata/SAML"
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

d) Restart Tomcat, Apache and shibd daemon, as it will be needed for configuring the IdP:

```
sp> ./control start
sp> sudo /etc/init.d/httpd start
sp> sudo /sbin/service shibd start
```

## IdP Setup

These instructions follow those provided in https://wiki.shibboleth.net/confluence/display/SHIB2/IdPSPLocalTestInstall
for setting up a Shibboleth IdP.

Apache HTTP, Tomcat, and the Shibboleth Identity Provider are downloaded as
part of the Vargrant setup. The following steps setup and configure the
software to serve as an IdP for the "simple" web application running in
Tomcat on the Shibboleth SP (192.168.33.20).

### Setup Shibboleth Identity Provider

8) Login to the IdP Vagrant:

```
repo> vagrant ssh idp
```

9) Switch to the "shib" service user (password: "shib"):

```
idp> su - shib
```

10) Switch to /apps/shibboleth-identityprovider-2.3.8, run the install
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
192.168.33.110
A keystore is about to be generated for you. Please enter a password that will be used to protect it.
shib
```

11) The "shib" service user has been added to the "sudoers" list, so edit the
/etc/httpd/conf/httpd.conf file:

```
idp> sudo vi /etc/httpd/conf/httpd.conf
```

and add the following line at the bottom of the file:

```
ProxyPass /idp/ ajp://localhost:8009/idp/
```

12) The Shibboleth IdP web application requires specific XML-related jar files
to run. Create an "endorsed" directory in /apps/tomcat/, and copy the jars
from the /apps/shibboleth-identityprovider-2.3.8/endorsed/ into it. The
/apps/tomcat/control script has been specially written to incorporate these
jars into the running Tomcat:

```
ipd> mkdir /apps/tomcat/endorsed
idp> cp /apps/shibboleth-identityprovider-2.3.8/endorsed/*.jar /apps/tomcat/endorsed
```

13) Modify AJP connector in /apps/tomcat/conf/server.xml  to allow Apache to
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

14) Edit /etc/http/conf/httpd.conf

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
See https://wiki.shibboleth.net/confluence/display/SHIB2/IdPAuthRemoteUser for more information.

15) Create the /usr/local/idp/credentials/, and then use htpasswd to add some
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

16) Stop Apache Tomcat, and copy the idp.war file into the Tomcat webapps
directory:

```
idp> sudo /etc/init.d/httpd stop
idp> cd /apps/tomcat
idp> ./control stop
idp> cp /apps/shibboleth-idp/war/idp.war webapps
```

17) Edit the /apps/shibboleth-idp/conf/relying-party.xml file to configure the
IdP for use with the SP:

```
idp> vi /apps/shibboleth-idp/conf/relying-party.xml
```

This requires adding the following lines, just after the "IdPMD" MetadataProvider in the "Metadata Configuration" section:

```                         
        <metadata:MetadataProvider xsi:type="metadata:FilesystemMetadataProvider"
                  id="MyMetadata"
                  metadataFile="/apps/shibboleth-idp/metadata/some-metadata.xml" />
```

18) We now need to set up the "some-metadata.xml" file that defines the SP metadata. The metadata is retrieved from the SP (in this case, the "sp-dev" SP by running the following command:

```
idp> curl -k https://192.168.33.120/Shibboleth.sso/Metadata > /apps/shibboleth-idp/metadata/some-metadata.xml
```
This writes the output of the Curl request into the /apps/shibboleth-idp/metadata/some-metadata.xml, which is referenced in the relying-party.xml configuration.

----
<strong>Note:</strong> 

The above Curl request will generate "AssertionConsumerService" entries in the "some-metadata.xml" file that only respond to "https" requests. (Using "https" results in the AssertionConsumerService entries having "https", using "http" will result in them having "http".)

Using the incorrect http/https when requesting the protected page will result in a "No peer endpoint available to which to send SAML response". So with the above Curl request, https://192.168.33.120/simple will work, but http://192.168.33.120/simple will result in a Shibboleth error.

If both http and https access is desired, then do the following:

a) On the SP, modify the /etc/shibboleth/shibboleth2.xml file, changing the line:

```
<Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>
```

to

```
<Handler type="MetadataGenerator" Location="/Metadata" https="true" signing="false"/>
```
b) Run the following Curl command on the IdP (instead of the Curl command above):

```
idp> curl http://192.168.33.120/Shibboleth.sso/Metadata > /apps/shibboleth-idp/metadata/some-metadata.xml
```

The /apps/shibboleth-idp/metadata/some-metadata.xml should now contains "AssertionConsumerService" entries for both "http" and "https" variants of the SP URL.

----

19) Examine the /apps/shibboleth-idp/metadata/some-metadata.xml:

```
idp> view /apps/shibboleth-idp/metadata/some-metadata.xml
```

it should look like:

```
 <!--
 This is example metadata only. Do *NOT* supply it as is without review,
 and do *NOT* provide it in real time to your partners.
  -->
 <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" ID="_7798da5827026d8cf5fdcdb337d7ed30a2e29bf2" entityID="https://example-app.lib.umd.edu/shibboleth">

  <md:Extensions xmlns:alg="urn:oasis:names:tc:SAML:metadata:algsupport">
 ...
```

### Restart SP and IdP Services

20) Restart the services on the IdP and SP machines:

```
sp> cd /apps/tomcat/
sp> ./control stop
sp> sudo /etc/init.d/httpd stop
sp> sudo /sbin/service shibd stop

idp> ./control start
idp> sudo /etc/init.d/httpd start

sp> ./control start
sp> sudo /etc/init.d/httpd start
sp> sudo /sbin/service shibd start

```

#### Verification steps:

a) Go to http://192.168.33.120/ - the "Apache 2 Test Page" should be displayed.

b) Go to http://192.168.33.120:8080/ - the Apache Tomcat page should be displayed

c) Go to http://192.168.33.120:8080/simple/ - a "Hello World" page should be displayed

d) Go to http://192.168.33.120/simple/ - the browser will display warnings about untrusted connections. After adding exceptions to bypass the warnings, you will be asked to login. After
login, a Shibboleth error "Error Message: No peer endpoint available to which to send SAML response" will be displayed. This is expected (see note above).

e) Go to https://192.168.33.110:443/ - the "Apache 2 Test Page" should be
displayed (you will likely get one or more warnings about the connection
being untrusted – this is expected).

f) Go to https://192.168.33.120/simple/ - the browser will display warnings about untrusted connections. After adding exceptions to bypass the warnings, you will be asked to login. Once you've logged in, the "Hello World" page should be displayed.

### Troubleshooting

Verify that the following files look as expected:

SP:

 * /etc/shibboleth/shibboleth2.xml
 
IdP:

 * /apps/shibboleth-idp/metadata/some-metadata.xml
 * /apps/shibboleth-idp/conf/relying-party.xml
 
The log files for the IdP in /apps/shibboleth-idp/logs/ (particularly the "idp-process.log" file) may also be helpful.

### Tying up the Loose Ends

There are several issues with the above setup:

 * It is possible to access the protected resource without logging in by going
directly to it via port 8080.

 * Shibboleth is not passing any useful attributes to the protected resource.

Note: These steps will not attempt to fix the Shibboleth error that occurs when accessing http://192.168.33.120/simple/, as all services should be using HTTPS.

#### Blocking port 8080 access to the protected resource

21) Following the advice in Chapter 6 of [O'Reilly's Tomcat: The Definitive Guide, 2nd Edition](http://proquest.safaribooksonline.com/book/programming/java/9780596101060),
block access to port 8080 at the firewall by running the following iptables
commands on the SP machine:

```
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8080 -d 192.168.33.120 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8009 -d 192.168.33.120 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8443 -d 192.168.33.120 -j DROP
sp> sudo /sbin/service iptables save
```

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login
sessions).

b) Go to http://192.168.33.120/ - the "Apache 2 Test Page" should be displayed.

c) Go to http://192.168.33.120:8080/ - the browser should wait, and then timeout.

d) Go to https://192.168.33.120/simple/ - Should be prompted for a login. After
login, the "Hello World" page should be displayed (you will likely get one or
more warnings about the connection being untrusted – this is expected).

e) Go to http://192.168.33.120:8080/simple/ - the browser should wait, and then
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

22) Edit the /apps/shibboleth-idp/conf/attribute-resolver.xml file:

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

23) Edit the /apps/shibboleth-idp/conf/attribute-filter.xml file:

```
idp> sudo vi /apps/shibboleth-idp/conf/attribute-filter.xml
```

uncommenting the "&lt;afp:AttributeFilterPolicy>" stanza (the portal example)
at the end of the file and changing it to:

```
    <afp:AttributeFilterPolicy>
        <afp:PolicyRequirementRule xsi:type="basic:AttributeRequesterString" value="https://example-app.lib.umd.edu/shibboleth" />
        <afp:AttributeRule attributeID="eduPersonAffiliation">
            <afp:PermitValueRule xsi:type="basic:ANY" />
        </afp:AttributeRule>
        <afp:AttributeRule attributeID="eduPersonEntitlement">
            <afp:PermitValueRule xsi:type="basic:ANY" />
        </afp:AttributeRule>
    </afp:AttributeFilterPolicy>
```

##### SP Setup

24) Edit the /etc/shibboleth/shibboleth2.xml file:

```
sp> sudo vi /etc/shibboleth/shibboleth2.xml
```

adding an "attributePrefix="AJP_" attribute to the &lt;ApplicationDefaults>
stanza, i.e.:

```
    <ApplicationDefaults entityID="https://example-app.lib.umd.edu/shibboleth"
                         REMOTE_USER="eppn persistent-id targeted-id"
                         attributePrefix="AJP_">
```

This is necessary for the AJP protocol used by Tomcat.

No changes are needed on the SP to support the two attributes being used in
this example. For other attributes, the /etc/shibboleth/attribute-map.xml might
need to be edited to map particular attributes to particular names for use by
the Java servlet.

25) Restart the Tomcat and Apache services on the IdP machine, and the Tomcat,
Apache, and shibd daemon on the SP machine:

```
sp> cd /apps/tomcat/
sp> ./control stop
sp> sudo /etc/init.d/httpd stop
sp> sudo /sbin/service shibd stop

idp> ./control stop
idp> sudo /etc/init.d/httpd stop

idp> ./control start
idp> sudo /etc/init.d/httpd start

sp> ./control start
sp> sudo /etc/init.d/httpd start
sp> sudo /sbin/service shibd start

```

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login sessions).

b) Go to https://192.168.33.120/simple/ - After logging in the page should
display the following two parameters, along with some others:

 * entitlement = urn:mace:dir:entitlement:common-lib-terms;urn:example.org:entitlement:entitlement1
 * unscoped-affiliation = member

----

### Troubleshooting Attributes

#### Attributes on the IdP

a) The "aacli.sh" script

The Shibboleth IdP application has a "aacli.sh" script to return what attributes
will be sent to a particular SP for a particular user. 

See https://wiki.shibboleth.net/confluence/display/SHIB2/AACLI for more information.

For some reason, the Shibboleth IdP doesn't include the servlet-api.jar, so the
"aacli.sh" script doesn't work out of the box (it gives ClassNotFoundExceptions
when you try to run it). To fix this, simply copy the servlet-api.jar file into
the "lib" directory, i.e.:

```
idp> cp /apps/tomcat/lib/servlet-api.jar /apps/shibboleth-idp/lib/
```

To see what attributes will be sent to the SP for the "myself" user, run the
following commands:

```
idp> /apps/shibboleth-idp/bin/aacli.sh --configDir /apps/shibboleth-idp/conf --principal myself --requester https://example-app.lib.umd.edu/shibboleth
```

This will print out XML containing the attributes sent to the SP.

b) IdP Logging Level

Increasing the logging level on the IdP can be very helpful for diagnosing problems with attributes. To do this, edit the /apps/tomcat/shibboleth-idp/conf/logging.xml file

```
idp> vi /apps/shibboleth-idp/conf/logging.xml
```

and change the following line from "INFO" to something more verbose such as "DEBUG" or "TRACE":

```
<logger name="edu.internet2.middleware.shibboleth" level="INFO"/>
```

Tomcat will need to be restarted for the change to take effect.

The log file is /apps/shibboleth-idp/logs/idp-process.log

#### Attributes on the SP

c) On the SP, edit the /etc/shibboleth/shibboleth2.xml, changing the
"showAttributeValues" flag in the Sessions handler to "true", i.e.:

```
<Sessions ..>
...
  <!-- Session diagnostic service. -->
  <Handler type="Session" Location="/Session" showAttributeValues="true"/>
...
</Sessions>
```

d) Go to the protected resource https://192.168.33.20/simple. After logging in,
(and dealing with any warnings about untrusted connections) go to
https://192.168.33.20/Shibboleth.sso/Session. Information about the
session, including the attributes, will be displayed.

### sp-production Prerequisite

Before configuring the "sp-production" machine, we need to copy the private key used by Shibboleth to encrypt communications between the IdP and SP to the /vagrant directory, so that it is available for copying into the "sp-production" configuration.

This is necessary, because the "public" key in the /apps/shibboleth-idp/metadata/some-metadata.xml file is used to encrypt communications between the IdP and SP, so both SPs need to have access to the private key in order to decrypt the response from the IdP.

26) Copy the Shibboleth private key files to /vagrant:

```
sp> sudo cp /etc/shibboleth/sp-key.pem /vagrant
sp> sudo cp /etc/shibboleth/sp-cert.pem /vagrant
```

## sp-production Setup

For the "sp-production" machine, do the following:

27) Login to the "sp-production" Vagrant box:


```
repo> vagrant ssh sp-production
```

28) For the"sp-production" setup perform steps 2-7. In Step 2, when creating a self-signed certificate, the hostname is "192.168.33.130" instead of "192.168.120"

29) Perform step 24 (editing the "/etc/shibboleth/shibboleth2.xml" file)

30) In the IdP, edit the "/apps/shibboleth-idp/metadata/some-metadata.xml" file:

```
idp> vi /apps/shibboleth-idp/metadata/some-metadata.xml
```

and add the following lines, after the other "AssertionConsumerServices" entries:

```
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://192.168.33.130/Shibboleth.sso/SAML2/POST" index="7"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign" Location="https://192.168.33.130/Shibboleth.sso/SAML2/POST-SimpleSign" index="8"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="https://192.168.33.130/Shibboleth.sso/SAML2/Artifact" index="9"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:PAOS" Location="https://192.168.33.130/Shibboleth.sso/SAML2/ECP" index="10"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:1.0:profiles:browser-post" Location="https://192.168.33.140/Shibboleth.sso/SAML/POST" index="11"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:1.0:profiles:artifact-01" Location="https://192.168.33.130/Shibboleth.sso/SAML/Artifact" index="12"/>

```

31) Copy the Shibboleth from sp-dev into sp-production by running the following commands:

```
sp> sudo cp /vagrant/sp-key.pem /etc/shibboleth/sp-key.pem
sp> sudo cp /vagrant/sp-cert.pem /etc/shibboleth/sp-cert.pem
```

32) Block port 8080 access by running the following commands:

```
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8080 -d 192.168.33.130 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8009 -d 192.168.33.130 -j DROP
sp> sudo /sbin/iptables -A INPUT -p tcp --dport 8443 -d 192.168.33.130 -j DROP
sp> sudo /sbin/service iptables save
```

33) Restart the services on the "idp" and "sp-production" machines:

```
sp> cd /apps/tomcat/
sp> ./control stop
sp> sudo /etc/init.d/httpd stop
sp> sudo /sbin/service shibd stop

idp> cd /apps/tomcat/
idp> sudo /etc/init.d/httpd stop
idp> ./control stop

idp> ./control start
idp> sudo /etc/init.d/httpd start

sp> ./control start
sp> sudo /etc/init.d/httpd start
sp> sudo /sbin/service shibd start
```

#### Verification steps:

a) Restart the browser being used for testing (this clears any previous login sessions).

b) Go to https://192.168.33.130/simple/ - After logging in the page should
display the following two parameters, along with some others:

 * entitlement = urn:mace:dir:entitlement:common-lib-terms;urn:example.org:entitlement:entitlement1
 * unscoped-affiliation = member

----

## License

These files are provided under the CC0 1.0 Universal license (http://creativecommons.org/publicdomain/zero/1.0/).
