#!/usr/bin/env bash

az policy assignment create --name tagging-policy \
                            --display-name "Ensure all indexed resources are tagged assignment" \
                            --policy tagging-policy-definition \
                            --params "{ \"tagName\": {\"value\": \"Name\"} }"
