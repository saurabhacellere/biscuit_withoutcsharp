# Downloading latest version of utPLSQL

To download latest version of utPLSQL from github on both Unix/Linux as well as Windows machines use the below smippets.

## Unix/Linux

```bash
#!/bin/bash
# Get the url to latest release "zip" file
UTPLSQL_DOWNLOAD_URL=$(curl --silent https://api.github.com/repos/utPLSQL/utPLSQL/releases/latest | awk '/browser_download_url/ { print $2 }' | grep ".zip" | sed 's/"//g')
# Download the latest release "zip" file
curl -Lk "${UTPLSQL_DOWNLOAD_URL}" -o utPLSQL.zip
# Extract downloaded "zip" file
unzip -q utPLSQL.zip
```

You may download with a one-liner if that is more convenient.
```bash
#!/bin/bash
curl -LOk $(curl --silent https://api.github.com/repos/utPLSQL/utPLSQL/releases/latest | awk '/browser_download_url/ { print $2 }' | grep ".zip" | sed 's/"//g') 
```

## Windows

To run the script on windows you will need [PowerShell 3.0](https://blogs.technet.microsoft.com/heyscriptingguy/2013/06/02/weekend-scripter-install-powershell-3-0-on-windows-7/) or above. 
You will also need .NET 4.0 Framework or above.

```batch
$archiveName = 'utPLSQL.zip'
$latestRepo = Invoke-WebRequest https://api.github.com/repos/utPLSQL/utPLSQL/releases/latest
$repo = $latestRepo.Content | Convertfrom-Json

$urlList = $repo.assets.browser_download_url

Add-Type -assembly "system.io.compression.filesystem"

foreach ($i in $urlList) {

   $fileName = $i.substring($i.LastIndexOf("/") + 1)

   if ( $fileName.substring($fileName.LastIndexOf(".") + 1) -eq 'zip' ) {
      Invoke-WebRequest $i -OutFile $archiveName
      $fileLocation = Get-ChildItem | where {$_.Name -eq $archiveName}

      if ($fileLocation) {
         [io.compression.zipfile]::ExtractToDirectory($($fileLocation.FullName),$($fileLocation.DirectoryName))   
      }
   }
}
```

# Supported database versions

The utPLSQL may be installed on any supported version of Oracle Database [see](http://www.oracle.com/us/support/library/lifetime-support-technology-069183.pdf#page=6)
* 11g R2 
* 12c
* 12c R2
* 18c

# Headless installation

To install the utPLSQL into a new database schema and grant it to public, execute the script `install_headless.sql` as SYSDBA.

The script accepts three optional parameters that define:
- username to create as owner of utPLSQL (default `ut3`)  
- password for owner of utPLSQL (default `XNtxj8eEgA6X6b6f`)
- tablespace to use for storage of profiler data (default `users`)  

Example invocation of the script from command line:
```bash
cd source
sqlplus sys/sys_pass@db as sysdba @install_headless.sql  
```

Invoking script with parameters:
```bash
cd source
sqlplus sys/sys_pass@db as sysdba @install_headless.sql utp3 my_verySecret_password utp3_tablespace   
```

The script needs to be executed by `SYSDBA`, in order to grant access to `DBMS_LOCK` and `DBMS_CRYPTO` system packages.


# Recommended Schema
It is highly recommended to install utPLSQL in it's own schema. You are free to choose any name for this schema.
Installing uPLSQL into shared schema is really not recommended as you loose isolation of framework.

If the installation and utPLSQL owner user is one and the same, the user must have the following Oracle system permissions before you can proceed with the installation.

  - CREATE SESSION
  - CREATE PROCEDURE
  - CREATE TYPE
  - CREATE TABLE
  - CREATE SEQUENCE
  - CREATE VIEW
  - CREATE SYNONYM
  - ALTER SESSION
  
In addition the user must be granted the execute privilege on `DBMS_LOCK` and `DBMS_CRYPTO` packages.
    
utPLSQL is using [DBMS_PROFILER tables](https://docs.oracle.com/cd/E18283_01/appdev.112/e16760/d_profil.htm#i999476) for code coverage. The tables required by DBMS_PROFILER will be created in the installation schema unless they already exist.
The uninstall process will **not** drop profiler tables, as they can potentially be shared and reused for profiling PLSQL code.

It is up to DBA to maintain the storage of the profiler tables.

# Manual installation procedure

### Creating schema for utPLSQL
To create the utPLSQL schema and grant all the required privileges execute script `create_utplsql_owner.sql` from the `source` directory with parameters:

  - `user name` - the name of the user that will own of utPLSQL object
  - `password`  - the password to be set for that user
  - `tablespace name` - the tablespace name to hold data created during test execution

Example invocation:
```bash
cd source
sqlplus sys/sys_password@database as sysdba @create_utPLSQL_owner.sql ut3 ut3 users  
```

### Installing utPLSQL
To install the utPLSQL framework into your database run the `/source/install.sql` script and provide `schema_name` where utPLSQL is to be installed.  
Schema must be created prior to calling the `install` script.
You may install utPLSQL from any account that has sufficient privileges to create objects in other users schema.  

Example invocation:
```bash
cd source
sqlplus admin/admins_password@database @install.sql ut3  
```

### Allowing other users to access the utPLSQL framework
In order to allow other users to access utPLSQL, synonyms must be created and privileges granted.
You have two options:

  - use grants and synonyms to public, to allow all users to access the framework
  - use synonyms and grants for individual users to limit the access to the framework
 
To grant utPLSQL to public execute script `source/create_synonyms_and_grants_for_public.sql` and provide `schema_name` where utPLSQL is installed. 

Example invocation:
```bash
cd source
sqlplus admin/admins_password@database @create_synonyms_and_grants_for_public.sql ut3  
```
To grant utPLSQL to an individual user, execute scripts `source/create_user_grants.sql` and `source/create_user_synonyms.sql`, provide `schema_name` where utPLSQL is installed and `user_name` to grant access for.

Example invocation:
```bash
cd source
sqlplus ut3_user/ut3_password@database @create_user_grants.sql ut3 hr
sqlplus user/user_password@database @create_user_synonyms.sql ut3 hr
```

The following tools that support the SQL*Plus commands can be used to run the installation script:

  - SQL*Plus
  - [SQLcl](http://www.oracle.com/technetwork/developer-tools/sqlcl/overview/index.html)
  - [Oracle SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html)
 
# Additional requirements

In order to use the Code Coverage functionality of utPLSQL, users executing the tests must have the CREATE privilege on the PLSQL code that the coverage is gathered on.
This is a requirement of [DBMS_PROFILER package](https://docs.oracle.com/cd/E18283_01/appdev.112/e16760/d_profil.htm#i999476).

In practice, user running tests for PLSQL code that he does not own, needs to have CREATE ANY PROCEDURE/CREATE ANY TRIGGER privileges.
Running code coverage on objects that the user does not own will **not produce any coverage information** without those privileges.

# Uninstalling utPLSQL

To uninstall run `uninstall.sql` and provide `schema_name` where utPLSQL is installed.

Example invocation:
```bash
cd source
sqlplus admin/admins_password@database @uninstall.sql ut3
```

The uninstall script will remove all the objects installed by the install script.
Additionally, all the public and private synonyms pointing to the objects in the utPLSQL schema will be removed.

If you have extended any utPLSQL types such as a custom reporter, these will need to be dropped before the uninstall, otherwise the uninstall script might fail.

The uninstall script does not drop the schema.

In order for the uninstall to be successful, you need to use the uninstall script that was provided with the exact utPLSQL version installed on your database.
i.e. the uninstall script provided with version 3.0.1 will probably not work if you want to remove version 3.0.0 from your database.

# Version upgrade

Currently, the only way to upgrade version of utPLSQL v3.0.0 and above is to remove the previous version and install the new version.

# Working with utPLSQL v2

If you are using utPLSQL v2, you can still install utPLSQL v3.
The only requirement is that utPLSQL v3 needs to be installed in a different schema than utPLSQL v2.

utPLSQL v3 and utPLSQL v2 do not collide on public synonym names. 
