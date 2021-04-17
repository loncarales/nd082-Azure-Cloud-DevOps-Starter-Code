# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

#### Azure Policy Deploying

First we need to sign in with Azure CLI. Locally, we can sign in interactively through the browser with the `az login` command.
When writing scripts, the recommended approach is to use service principals. By granting just the appropriate permissions needed to a service principal, you can keep your automation secure.
You can read more about the ways to sign in [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli).

Deploy a policy definition and apply it

```bash
cd policyAssignment
# first create a policy definition
./create-policy-definition.sh
# then create a policy assignment
./apply-policy-definition.sh
# Check the policy which was created
az policy assignment list
```
#### Create a Packer image

Packer builds images by taking a base image and installing additional software on it.

To use Packer with Azure, you must [create a service principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) with the Azure CLI.

To use a service principal you must specify `subscription_id`, `client_id`, `tenant_id` and `client_secret`.

##### Packer Configuration Files

Copy a `.envrc-local` file to `.envrc` file in packer folder. This file is bash code that is going to be loaded by a shell script. To configure Packer to use your Service Principals information and set the following environment variables.

```bash
export ARM_CLIENT_ID=<<<ARM_CLIENT_ID>>>
export ARM_CLIENT_SECRET=<<<ARM_CLIENT_SECRET>>>
export ARM_SUBSCRIPTION_ID=<<<ARM_SUBSCRIPTION_ID>>>
export ARM_TENANT_ID=<<<ARM_TENANT_ID>>>
```

Create an image resource group named `udacity-demo-rg`.

Create the image using Packer.

```bash
cd packer
# Run the shell script
./build-vm.sh
```

#### Deploy Azure resources with Terraform

##### Terraform Configuration Files

Copy a `.envrc-local` file to `.envrc` file in terraform folder. This file is bash code that is going to be loaded by a shell script. To configure Terraform to use your Service Principals information and set the following environment variables.

```bash
export ARM_CLIENT_ID=<<<ARM_CLIENT_ID>>>
export ARM_CLIENT_SECRET=<<<ARM_CLIENT_SECRET>>>
export ARM_SUBSCRIPTION_ID=<<<ARM_SUBSCRIPTION_ID>>>
export ARM_TENANT_ID=<<<ARM_TENANT_ID>>>
```

Create a local SSH key

```bash
cd terraform
ssh-keygen -t rsa -C "Terraform" -f ./tf
```

To Provision infrastructure using Terraform run `./provision-infra.sh` script.

#### Destroy all Azure resources once you don't need them

```bash
cd terraform
# Destroy Infrastructure
terraform destroy
# Destroy image built by Packer using the command 
az image delete -g udacity-demo-rg -n vmhelloworld001
```

### Output

The Terraform will output the public HTTP service IP address of the load balancer in front of the webservers.

```bash
# Sample output
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

public_IP_Load_Balancer = "20.62.141.46"
```
