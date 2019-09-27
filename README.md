[![Build Status - Develop](https://travis-ci.org/IBM-Swift/swift-buildpack.svg?branch=develop)](https://travis-ci.org/IBM-Swift/swift-buildpack)

IBM Cloud buildpack for Swift
===============================

This is the IBM Cloud buildpack for Swift applications, powered by the Swift Package Manager (SPM). Though this buildpack was developed mainly for IBM Cloud and the sample commands use the IBM Cloud [command line](https://clis.cloud.ibm.com/ui/home.html), it can be used on any Cloud Foundry environment. This buildpack requires access to the Internet for downloading and installing several system level dependencies.

Check out the [Kitura-Starter](https://github.com/IBM-Cloud/Kitura-Starter) for a fully working example of a Kitura-based server application that can be deployed to the IBM Cloud (or any Cloud Foundry environment).

Usage
-----

Example usage (see the [Specify a Swift version](#specify-a-swift-version) section):

```shell
$ ibmcloud app push
Invoking 'ibmcloud app push'...

Using manifest file /Users/gvalenc/git/DevX/Kitura-Starter/manifest.yml
Getting app info...
Creating app with these attributes...
+ name:         kitura-starter-swift51
  path:         /Users/gvalenc/git/DevX/Kitura-Starter
  buildpacks:
+   https://github.com/IBM-Swift/swift-buildpack
+ command:      Kitura-Starter
+ disk quota:   1G
+ instances:    1
+ memory:       256M
  routes:
+   kitura-starter-swift51-turbulent-buffalo.mybluemix.net

Creating app kitura-starter-swift51...
Mapping routes...
Comparing local files to remote cache...
Packaging files to upload...
Uploading files...
 30.50 KiB / 30.50 KiB [==================================================================================] 100.00% 1s

Waiting for API to complete processing files...

Staging app and tracing logs...
   Cell 4506b303-dccf-48d5-9f39-7c6ac85ff0da creating container for instance 0dc09158-a961-42cc-acef-77853eed9182
   Cell 4506b303-dccf-48d5-9f39-7c6ac85ff0da successfully created container for instance 0dc09158-a961-42cc-acef-77853eed9182
   Downloading app package...
   Downloaded app package (30.5K)
   -----> Buildpack version 2.2.0
   -----> Default supported Swift version is 5.1
   -----> Configure for apt-get installs...
   -----> Writing profile script...
   -----> Copying deb files to installation folder...
   -----> No Aptfile found.
   -----> Getting swift-5.1
          Downloaded swift-5.1
   -----> Unpacking swift-5.1.tar.gz
   -----> Getting clang-8.0.0
          Downloaded clang-8.0.0
   -----> Unpacking clang-8.0.0.tar.xz
   -----> .ssh directory and config file not found.
   -----> Skipping cache restore (new swift signature)
   -----> Fetching Swift packages and parsing Package.swift files...
          Fetching https://github.com/apple/swift-log.git
          Fetching https://github.com/IBM-Swift/BlueSignals.git
          Fetching https://github.com/IBM-Swift/Kitura.git
          Fetching https://github.com/IBM-Swift/Swift-cfenv.git
          Fetching https://github.com/IBM-Swift/OpenSSL.git
          Fetching https://github.com/IBM-Swift/KituraContracts.git
          Fetching https://github.com/IBM-Swift/BlueSSLService.git
          Fetching https://github.com/IBM-Swift/BlueSocket.git
          Fetching https://github.com/IBM-Swift/CloudEnvironment.git
          Fetching https://github.com/IBM-Swift/Kitura-net.git
          Fetching https://github.com/IBM-Swift/HeliumLogger.git
          Fetching https://github.com/IBM-Swift/LoggerAPI.git
          Fetching https://github.com/IBM-Swift/FileKit.git
          Fetching https://github.com/IBM-Swift/Kitura-TemplateEngine.git
          Fetching https://github.com/IBM-Swift/Configuration.git
          Fetching https://github.com/IBM-Swift/TypeDecoder.git
          Fetching https://github.com/IBM-Swift/Health.git
   Completed resolution in 19.04s
          Cloning https://github.com/IBM-Swift/LoggerAPI.git
          Resolving https://github.com/IBM-Swift/LoggerAPI.git at 1.9.0
          Cloning https://github.com/IBM-Swift/OpenSSL.git
          Resolving https://github.com/IBM-Swift/OpenSSL.git at 2.2.2
          Cloning https://github.com/IBM-Swift/BlueSSLService.git
          Resolving https://github.com/IBM-Swift/BlueSSLService.git at 1.0.48
          Cloning https://github.com/IBM-Swift/TypeDecoder.git
          Resolving https://github.com/IBM-Swift/TypeDecoder.git at 1.3.3
          Cloning https://github.com/IBM-Swift/CloudEnvironment.git
          Resolving https://github.com/IBM-Swift/CloudEnvironment.git at 9.1.0
          Cloning https://github.com/IBM-Swift/BlueSignals.git
          Resolving https://github.com/IBM-Swift/BlueSignals.git at 1.0.20
          Cloning https://github.com/IBM-Swift/FileKit.git
          Resolving https://github.com/IBM-Swift/FileKit.git at 0.0.2
          Cloning https://github.com/IBM-Swift/BlueSocket.git
          Resolving https://github.com/IBM-Swift/BlueSocket.git at 1.0.48
          Cloning https://github.com/IBM-Swift/KituraContracts.git
          Resolving https://github.com/IBM-Swift/KituraContracts.git at 1.1.3
          Cloning https://github.com/apple/swift-log.git
          Resolving https://github.com/apple/swift-log.git at 1.1.0
          Cloning https://github.com/IBM-Swift/Configuration.git
          Resolving https://github.com/IBM-Swift/Configuration.git at 3.0.4
          Cloning https://github.com/IBM-Swift/Swift-cfenv.git
          Resolving https://github.com/IBM-Swift/Swift-cfenv.git at 6.0.3
          Cloning https://github.com/IBM-Swift/Kitura-net.git
          Resolving https://github.com/IBM-Swift/Kitura-net.git at 2.3.0
          Cloning https://github.com/IBM-Swift/Health.git
          Resolving https://github.com/IBM-Swift/Health.git at 1.0.5
          Cloning https://github.com/IBM-Swift/HeliumLogger.git
          Resolving https://github.com/IBM-Swift/HeliumLogger.git at 1.9.0
          Cloning https://github.com/IBM-Swift/Kitura.git
          Resolving https://github.com/IBM-Swift/Kitura.git at 2.8.1
          Cloning https://github.com/IBM-Swift/Kitura-TemplateEngine.git
          Resolving https://github.com/IBM-Swift/Kitura-TemplateEngine.git at 2.0.1
   -----> No additional packages to download.
   -----> Skipping installation of App Management (debug)
   -----> Installing system level dependencies...
   -----> Building Package...
   -----> Build config: release
          [1/7] Compiling Signals Signals.swift
          [2/8] Compiling KituraTemplateEngine TemplateEngine.swift
          [3/8] Compiling CHTTPParser utils.c
          [4/8] Compiling CHTTPParser http_parser.c
          [5/8] Compiling Logging Locks.swift
          [6/9] Compiling LoggerAPI Logger.swift
          [7/11] Compiling TypeDecoder OrderedDictionary.swift
          [8/12] Compiling HeliumLogger HeliumLogHandler.swift
          [9/12] Compiling Socket Socket.swift
          [10/13] Compiling Health Health.swift
          [11/14] Compiling FileKit FileKit.swift
          [12/15] Compiling SSLService SSLPointerTricks.swift
          [13/16] Compiling Configuration ConfigurationManager.swift
          [14/17] Compiling CloudFoundryEnv App.swift
          [15/18] Compiling CloudEnvironment AlertNotificationCredentials.swift
          [16/18] Compiling KituraContracts BodyDecoder.swift
          [17/18] Compiling KituraNet BufferList.swift
          [18/19] Compiling Kitura AdditionalCookieAttribute.swift
          [19/20] Compiling Controller Controller.swift
          [20/21] Compiling Kitura-Starter main.swift
          [21/21] Linking Kitura-Starter
   -----> Bin path: /tmp/app/.build/x86_64-unknown-linux/release
   -----> Copying dynamic libraries
   -----> Copying binaries to 'bin'
   -----> Clearing previous swift cache
   -----> Skipping cache save (disabled by default)
   -----> Optimizing contents of cache folder...
   No start command specified by buildpack or via Procfile.
   App will not start unless a command is provided at runtime.
   Exit status 0
   Uploading droplet, build artifacts cache...
   Uploading droplet...
   Uploading build artifacts cache...
   Uploaded build artifacts cache (2K)
   Uploaded droplet (259.5M)
   Uploading complete
   Cell 4506b303-dccf-48d5-9f39-7c6ac85ff0da stopping instance 0dc09158-a961-42cc-acef-77853eed9182
   Cell 4506b303-dccf-48d5-9f39-7c6ac85ff0da destroying container for instance 0dc09158-a961-42cc-acef-77853eed9182

Waiting for app to start...

name:              kitura-starter-swift51
requested state:   started
routes:            kitura-starter-swift51-turbulent-buffalo.mybluemix.net
last uploaded:     Thu 26 Sep 10:52:49 CDT 2019
stack:             cflinuxfs3
buildpacks:        https://github.com/IBM-Swift/swift-buildpack

type:            web
instances:       1/1
memory usage:    256M
start command:   Kitura-Starter
     state     since                  cpu    memory        disk           details
#0   running   2019-09-26T15:53:33Z   1.9%   36K of 256M   194.5M of 1G
```

The buildpack will detect your app as Swift if it has a `Package.swift` file in the root.

### Version installed on the IBM Cloud

The latest version of the IBM Cloud buildpack for Swift on the IBM Cloud is [v2.2.0](https://github.com/IBM-Swift/swift-buildpack/releases/tag/2.2.0).

Please note that it is possible that the latest buildpack code contained in this repo hasn't yet been installed on the IBM Cloud. If that happens to be the case and you'd like to leverage the latest buildpack code, you can do so by adding the `-b https://github.com/IBM-Swift/swift-buildpack` parameter to the `ibmcloud app push` command, as shown below:

```shell
ibmcloud app push -b https://github.com/IBM-Swift/swift-buildpack
```

### Procfile

Using the `Procfile`, you specify the name of the executable process (e.g. `Server`) to run for your web server. Any binaries built from your Swift source using SPM will be placed in your $PATH. You can also specify any runtime parameters for your process in the `Procfile`.

```
web: Server --bind 0.0.0.0:$PORT
```

### Alternative to Procfile

Instead of using the `Procfile`, you can use the `command` attribute in the `manifest.yml` of your application to specify the name of your executable. The snippet of code below shows how to use the `command` attribute to specify the same executable and parameter values used in the above `Procfile` example:

```
command: Server -bind 0.0.0.0:$PORT
```

For further details on the `command` attribute, see the [command attribute section](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#start-commands) on the Cloud Foundry documentation.

### Swift-cfenv

Instead of specifying IP address and port values in the `Procfile` (or in the `command` attribute) as runtime parameters to your web server process, you can instead use the [Swift-cfenv](https://github.com/IBM-Swift/Swift-cfenv) package to obtain such values at runtime. The Swift-cfenv package provides structures and methods to parse Cloud Foundry-provided environment variables, such as the port number, IP address, and URL of the application. It also provides default values when running the application locally. For details on how to leverage this library in your Swift application, see the [README](https://github.com/IBM-Swift/Swift-cfenv) file. When using Swift-cfenv in your app, your `Procfile` will be very simple; it will more than likely look like this:

```
web: <executable_name>
```

If instead of the `Procfile`, you are using the `command` attribute in your application's `manifest.yml` file, then the entry for the `command` attribute is simplified to:

```
command: <executable_name>
```

### What is the latest version of Swift supported?

The latest version of Swift supported by this buildpack is ```5.1```.

### Specify a Swift version

You specify the version of Swift for your application using a `.swift-version` file in the root of your repository:

```shell
$ cat .swift-version
5.1
```

Please note that the swift_buildpack installed on the IBM Cloud **caches** the following versions of the Swift binaries:

- `5.1`
- `5.0.2`
- `4.2.4`

If you'd like to use a different version of Swift [that is not cached] on the IBM Cloud, you can specify it in the `.swift-version` file.  Please be aware that using a Swift version that is not cached increases the provisioning time of your app on the IBM Cloud.

The [manifest.yml](https://github.com/IBM-Swift/swift-buildpack/blob/develop/manifest.yml) file contains the complete list of the Swift versions that are cached on the IBM Cloud.

Since there are frequent Swift language changes, it's advised that you pin your application to a specific Swift version. Once you have tested and migrated your code to a newer version of Swift, you can then update the `.swift-version` file with the appropriate Swift version.

### Installing additional system level dependencies
Many Swift applications will not require the installation of any additional libraries. It's very common for today’s applications to have dependencies only on services that provide REST interfaces to interact with them (e.g., Cloudant, AlchemyAPI, Personality Insights, etc.).

However, since dependencies vary from application to application, there could be cases when additional system packages may be required to compile and/or execute a Swift application. To address this need, the IBM Cloud buildpack for Swift supports the installation of Ubuntu trusty packages using the `apt-get` utility. You can specify the Ubuntu packages that the should be installed by including an `Aptfile` in the root directory of your Swift application. Each line in the Aptfile should contain a valid Ubuntu package name. For instance, if your application has a dependency on the `jsonbot` package, then your Aptfile should look like this:

```shell
$ cat Aptfile
jsonbot
```

### Installing closed source dependencies

For those accessing private or enterprise host respositories, the IBM Cloud buildpack for Swift now works with the Swift Package Manager to build these dependencies.  To leverage this capability, add a `.ssh` folder in the root of the application. This directory will need to contain the SSH keys needed to access the dependencies, as well as a `config` file referencing the keys. The example below shows the `config` and `Package.swift` files, respectively, which use the same SSH key to access private and public repositories in enterprise and standard GitHub accounts:

```shell
$ cat config
# GitHub.IBM.com - Enterprise Host, Account Key
Host github.ibm.com
    HostName github.ibm.com
    User git
    IdentityFile ~/.ssh/ssh_key

# GitHub.com - Private Repo, Account Key
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/ssh_key
```

You should use the `git` protocol in your `Package.swift` for those dependencies that are private or stored in an enterprise solution (e.g. GitHub Enterprise) as shown below. If you use the `https` protocol instead, then the buildpack will not be able to clone those dependencies.

```shell
$ cat Package.swift
...
dependencies: [
     ...
    .Package(url: "git@github.ibm.com:Org1/repo1.git", majorVersion: 1, minor: 0),
    .Package(url: "git@github.ibm.com:Org1/repo2.git", majorVersion: 1, minor: 0),
    .Package(url: "git@github.com:Org2/repo3.git", majorVersion: 0, minor: 0),
    ...
  ]
...
```

This approach works for both SSH account keys and deployment keys.  For the example below, three keys are used - two deployment keys for the enterprise GitHub, and one account key for the standard one.

```shell
$ cat config
# GitHub Enterprise - repo1 deployment key
Host enterprise1
    HostName github.ibm.com
    User git
    IdentityFile ~/.ssh/githubEnterprise_key1

# GitHub Enterprise - repo2 deployment key
Host enterprise2
    HostName github.ibm.com
    User git
    IdentityFile ~/.ssh/githubEnterprise_key2

# GitHub.com - Private Repo, Account Key
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
```

```shell
$ cat Package.swift
...
dependencies: [
     ...
    .Package(url: "git@enterprise1:Org1/repo1.git", majorVersion: 1, minor: 0),
    .Package(url: "git@enterprise2:Org1/repo2.git", majorVersion: 1, minor: 0),
    .Package(url: "git@github.com:Org2/repo3.git", majorVersion: 0, minor: 0),
    ...
  ]
...
```

### Additional compiler flags

To specify additional compiler flags for the execution of the `swift build` command, you can include a `.swift-build-options-linux` file. For example, in order to leverage the system package `libmysqlclient-dev` in a Swift application, you'd need an additional compiler flag:

```shell
$ cat .swift-build-options-linux
-Xswiftc -DNOJSON
```

When leveraging the PostgreSQL system library `libpq-dev`, the following contents should be added to the `.swift-build-options-linux` file:

```shell
$ cat .swift-build-options-linux
-Xcc -I/usr/include/postgresql
```

If you need to specify the path to header files for a system package installed by the buildpack, you can use the following:

```shell
-Xcc -I$BUILD_DIR/.apt/usr/include/<path to header files>
```

If you need to specify environment variables that apply during the build,, such as to enable [Kitura-NIO](https://github.com/IBM-Swift/Kitura-NIO#using-kitura-nio), create a file with the name `.swift-build-env-linux` in the root project directory. Edit the file and add one environment variable per line. For example:
```
KITURA_NIO=1
FOO=BAR
```

### libdispatch

Previous versions of this buildpack provided the [libdispatch](https://github.com/apple/swift-corelibs-libdispatch) binaries for Swift development builds **prior** to 2016-08-23. However, current and future versions of this buildpack will **not** provide those binaries. Users should upgrade their applications to Swift 3.0, which already includes the libdispatch binaries.

### Caching of the .build directory

Following the release of Swift 5.1, the IBM Cloud buildpack for Swift does not cache the contents of the `.build` folder by default. Caching this folder helps speed up the provisioning of your application the next time you execute the `ibmcloud app push` command, but can cause an application to exceed its disk space quota. If you'd prefer to use this caching mechanism, you can enable it by executing the following command:

```shell
ibmcloud app env-set <app_name> SWIFT_BUILD_DIR_CACHE true
ibmcloud app restage <app_name>
```

If at some point, you'd like to disable caching of the `.build` folder, you can do so by executing:

```shell
ibmcloud app env-set <app_name> SWIFT_BUILD_DIR_CACHE false
ibmcloud app restage <app_name>
```

Note that if at some point you change the contents of your `Package.swift` or `Package.resolved` (or `Package.pins` for older versions of Swift) file, the buildpack will automatically refetch the dependencies and update the cache accordingly. Also, if you do not initially push a `Package.resolved` file along with your application and you are using Swift 4.0 (or a later version), a new `Package.resolved` file will be generated. It is recommended that you always push a `Package.resolved` file along with your application (if using Swift 4.0 or later).

### Debugging

If the buildpack preparation or compilation steps are failing, you can enable some debugging using the following command:

```shell
ibmcloud app env-set <app_name> BP_DEBUG true
```

To deactivate:

```shell
ibmcoud app env-unset <app_name> BP_DEBUG
```

### Installing Personal Package Archives
The IBM Cloud buildpack for Swift does not support the installation of [Personal Package Archives](https://launchpad.net/ubuntu/+ppas) (PPAs). If your application requires the installation of one or more PPAs, we recommend using a different mechanism other than the IBM Cloud buildpack for Swift for provisioning your application to the IBM Cloud. For instance, you could use [Docker and Kubernetes](https://cloud.ibm.com/docs/containers/container_index.html) to provision your Swift application to the IBM Cloud (in your `Dockerfile`, you would add the instructions for installing any necessary PPAs).

Admin tasks
-----------

To install this buildpack:

```shell
wget https://github.com/IBM-Swift/swift-buildpack/releases/download/2.1.1/buildpack_swift_v2.1.1-20190821-1902.zip
ibmcloud cf create-buildpack swift_buildpack uildpack_swift_v2.1.1-20190821-1902.zip <position>
```

**Position** is a positive integer, sets priority, and is sorted from lowest to highest when listed using the `ibmcloud cf buildpacks` command.

And to update it:

```shell
wget https://github.com/IBM-Swift/swift-buildpack/releases/download/2.1.1/buildpack_swift_v2.1.1-20190821-1902.zip
ibmcloud cf update-buildpack swift_buildpack -p uildpack_swift_v2.1.1-20190821-1902.zip
```

For more details on installing buildpacks, see [Adding buildpacks to Cloud Foundry](https://docs.cloudfoundry.org/adminguide/buildpacks.html).

Packaging
---------
The buildpack zip file provided in each release is built using the `manifest.yml` file:

```shell
BUNDLE_GEMFILE=cf.Gemfile bundle install
BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager --cached --use-custom-manifest manifest.yml
```

For details on packaging buildpacks, see [buildpack-packager](https://github.com/cloudfoundry/buildpack-packager).
