# RMUD

[![Build Status](https://travis-ci.com/rmud/rmud.svg?branch=master)](https://travis-ci.com/rmud/rmud)

## Building

[Install Docker CE](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce)

[Allow running docker without sudo](https://docs.docker.com/install/linux/linux-postinstall/)

## Developing

### macOS

Minimum required macOS version: macOS 11 (Big Sur).

Install Xcode 13.2.1 or later.

Open `Package.swift`.

Set repository root as custom working directory:

 * Click on `rmud` scheme.
 * Choose `Edit Scheme...`.
 * In `Options` tab, select `[x] Use custom working directory`.
 * Select repository root.

Build: CMD-B.

Run: CMD-R.

