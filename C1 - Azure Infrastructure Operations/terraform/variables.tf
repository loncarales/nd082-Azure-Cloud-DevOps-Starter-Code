variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "udacity-C1"
}

variable "tags" {
  description = "A map of the tags to use for the resources that are deployed"
  type        = map(string)
  default = {
    Name = "udacity-C1"
  }
}

variable "resource_group_packer" {
  description = "Resource group used in Packer"
  default     = "udacity-demo-rg"
}

variable "image_name_packer" {
  description = "Virtual Image name created with Packer"
  default     = "vmhelloworld001"
}

variable "number_of_virtual_machines" {
  description = "The number of virtual machines that will be instantiated and will be part of the availability set."
  default     = 2
}

variable "application_port" {
  description = "The port that you want to expose to the external load balancer"
  default     = 80
}

variable "public_ssh_key" {
  description = "Path to Public SSH Key"
}
