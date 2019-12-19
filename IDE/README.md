# Dev toolset
```
$ sudo yum install centos-release-scl
$ sudo yum install devtoolset-7
$ scl enable devtoolset-7 bash
$ gcc -v
[output suppressed]
gcc version 7.3.1 20180303 (Red Hat 7.3.1-5) (GCC)
```
# Git client
```
$ sudo yum install git
$ git version
git version 1.8.3.1
```
# Maven
```
$ sudo yum install maven
$ mvn -version
Apache Maven 3.0.5 (Red Hat 3.0.5-17)
Maven home: /usr/share/maven
Java version: 1.8.0_232, vendor: Oracle Corporation
Java home: /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64/jre
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "3.10.0-957.el7.x86_64", arch: "amd64", family: "unix"
```

# Eclipse 2019-09
* CodeReady plug-in for OpenShift development
* PyDev plug-in for Python development
* CDT plug-in for C++ development
* Smoke test - created a project from gitea repo running on host (open Windows Firewall)