#!/usr/bin/env bash

echo "Load Environment variables"
source .envrc

echo "Build vmhelloworld001 VM Image in Azure"
packer build server.json
