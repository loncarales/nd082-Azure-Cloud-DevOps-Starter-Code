#!/usr/bin/env bash

echo "Load .envrc"
source .envrc

echo "Initialize a Terraform working directory"
terraform init

echo "Generate and show an execution plan"
terraform plan \
  -var "public_ssh_key=./tf.pub" \
  -out=solution.plan

read -r -p "Provision infrastructure? [Y/n] " input
 
case $input in
    [yY][eE][sS]|[yY])
echo "Provisioning!"
terraform apply \
  -var "public_ssh_key=./tf.pub"
 ;;
    [nN][oO]|[nN])
 echo "Skipping provisioning"
       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac
