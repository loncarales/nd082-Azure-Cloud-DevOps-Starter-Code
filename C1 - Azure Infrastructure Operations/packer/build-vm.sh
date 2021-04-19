#!/usr/bin/env bash

FILE=.envrc
if test -f "$FILE"; then
  echo "Load Environment variables"
  source $FILE
  echo "Build vmhelloworld001 VM Image in Azure"
  packer build server.json
fi
