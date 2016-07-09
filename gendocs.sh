#!/bin/sh

#version=`cat SelfSignedCert.podspec|grep "version"|cut -d ':' -f 2|sed "s|.*\"\(.*\)\".*|\1|"`
version=0.1

jazzy \
  --clean \
  --author "Stefan van den Oord" \
  --author_url https://github.com/svdo \
  --github_url https://github.com/svdo/swift-selfsignedcert \
  --github-file-prefix https://github.com/svdo/swift-selfsignedcert/tree/$version \
  --module-version $version \
  --module SelfSignedCert \
  --readme README.md \
  --copyright "Copyright © 2016 [Stefan van den Oord](https://github.com/svdo). All rights reserved" \
  --output docs
