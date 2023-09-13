# Install Nextcloud
Where some scripts used in Nextcloud can be found

## Getting Started

- Make sure `git`, `curl` and `subversion` programs are installed on your system.

# Ubuntu

Clone the subdirectory Ubuntu if your distribution is based on Debian or Ubuntu.

```
svn export https://github.com/edsonsbj/install-nextcloud/trunk/Ubuntu && cd Ubuntu/ && sudo chmod +x *.sh && sudo ./nextcloud-install.sh
```

# Dietpi

Clone the dietpi subdirectory if your system is dietpi. 

```
svn export https://github.com/edsonsbj/install-nextcloud/trunk/dietpi && cd dietpi/ && sudo chmod +x *.sh && sudo ./ncdietpi.sh
```
