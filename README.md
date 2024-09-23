# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
- [Installation](#installation)
- [Quickstart](#quick-start)
- [Maintenance](#maintenance)
    - [Shell Access](#shell-access)
- [References](#references)

# Introduction

Dockerfile to build a container image with qmail and ezmlm.

This container will run supervisord and start up 
- qmail-send and a qmail tcp server (for smtp)

This is only useful for running ezmlm based mailing lists. The
original repository by
[Maescool](https://github.com/Maescool/docker-qmail) has more features.

## Version

Current versions:
- netqmail: **1.0.6** (originally for qmail.org)
- ezmlm: github 7.2.2 version of https://github.com/bruceg/ezmlm-idx

# Configuration

## Data Store

if you don't want to lose your mail when the docker container is
stopped/deleted. To avoid losing any data, you should mount a volume
at,

* `/home` (for mailing lists)
* `/var/qmail/control`
* `/var/qmail/users`

# Maintenance

## Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it qmail bash
```

# References

  * http://www.qmail.org/netqmail/
  * http://www.lifewithqmail.org/
