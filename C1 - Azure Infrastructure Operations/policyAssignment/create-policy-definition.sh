#!/usr/bin/env bash

az policy definition create --name tagging-policy-definition \
                            --display-name "Ensure all indexed resources are tagged definition" \
                            --description "Policy that ensures all indexed resources in the subscription have tags and deny deployment if they do not." \
                            --rules EnforceTags.json --params TagParam.json \
                            --mode Indexed
