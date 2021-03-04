##################################################################################
# version - Terraform version required
##################################################################################
variable "TF_VERSION" {
  default     = "0.13"
  description = "terraform version required for schematics"
}

##################################################################################
# region - The VPC region to instatiate the F5 BIG-IP instance
##################################################################################
variable "region" {
  type        = string
  default     = "us-south"
  description = "The VPC region to instatiate the F5 BIG-IP instance"
}

##################################################################################
# resource_group - The IBM Cloud resource group to create the F5 BIG-IP instance
##################################################################################
variable "resource_group" {
  type        = string
  default     = "default"
  description = "The IBM Cloud resource group to create the F5 BIG-IP instance"
}

##################################################################################
# voltera_tenant - The Volterra tenant for API access
##################################################################################
variable "volterra_tenant" {
  type        = string
  default     = ""
  description = "The Volterra tenant for API access"
}

##################################################################################
# voltera_api_token - The Volterra token for API access
##################################################################################
variable "volterra_api_token" {
  type        = string
  default     = ""
  description = "The Volterra token for API access"
}

##################################################################################
# voltera_site_token - The Volterra site token
##################################################################################
variable "volterra_site_token" {
  type        = string
  default     = ""
  description = "The Volterra site token"
}

##################################################################################
# voltera_cluster_name - The Volterra cluster name created with the site token
##################################################################################
variable "volterra_cluster_name" {
  type        = string
  default     = ""
  description = "The Volterra cluster name created with the site token"
}

##################################################################################
# voltera_cluster_size - The Volterra cluster size
##################################################################################
variable "volterra_cluster_size" {
  type        = number
  default     = 1
  description = "The Volterra cluster size"
}

##################################################################################
# voltera_voltstack - Include voltstack
##################################################################################
variable "volterra_voltstack" {
  type        = bool
  default     = false
  description = "Include voltstack"
}

##################################################################################
# volterra_image_name - The image to be used when provisioning the Volterra CE instance
##################################################################################
variable "volterra_image_name" {
  type        = string
  default     = "volterra-ce-centos-7-2009-5-202103011045"
  description = "The image to be used when provisioning the Volterra CE instance"
}

##################################################################################
# site_latitude - The Volterra site Latitude
##################################################################################
variable "site_latitude" {
  type        = string
  default     = ""
  description = "The Volterra site Latitude"
}

##################################################################################
# site_longitude - The Volterra site Latitude
##################################################################################
variable "site_longitude" {
  type        = string
  default     = ""
  description = "The Volterra site Longitude"
}

##################################################################################
# instance_profile - The name of the VPC profile to use for the Volterra CE instnace
##################################################################################
variable "instance_profile" {
  type        = string
  default     = "cx2-4x8"
  description = "The resource profile to be used when provisioning the Volterra CE instance"
}

##################################################################################
# ssh_key_name - The name of the public SSH key (VPC Gen 2 SSH Key) to be used for the ops account
##################################################################################
variable "ssh_key_name" {
  type        = string
  default     = ""
  description = "The name of the public SSH key (VPC Gen 2 SSH Key) to be used for the ops account"
}

##################################################################################
# volterra_admin_password - The password for the built-in admin Volterra user
##################################################################################
variable "volterra_admin_password" {
  type        = string
  default     = ""
  description = "The password for the built-in admin Volterra user"
}

##################################################################################
# voltera_fleet_name - The Volterra fleet name to tag the cluster
##################################################################################
variable "volterra_fleet_name" {
  type        = string
  default     = ""
  description = "The Volterra fleet name to tag the cluster"
}

##################################################################################
# external_subnet_id - VPC Gen2 subnet ID for Volterra
##################################################################################
variable "external_subnet_id" {
  type        = string
  default     = ""
  description = "VPC Gen2 subnet ID for Volterra"
}

##################################################################################
# internal_subnet_id - VPC Gen2 subnet ID for internal resources
##################################################################################
variable "internal_subnet_id" {
  type        = string
  default     = ""
  description = "VPC Gen2 subnet ID for internal resources"
}

##################################################################################
# volterra_ssl_tunnels - Use SSL tunnels to connect to Volterra
##################################################################################
variable "volterra_ssl_tunnels" {
  type        = bool
  default     = false
  description = "Use SSL tunnels to connect to Volterra"
}

##################################################################################
# volterra_ipsec_tunnels - Use IPSEC tunnels to connect to Volterra
##################################################################################
variable "volterra_ipsec_tunnels" {
  type        = bool
  default     = true
  description = "Use IPSEC tunnels to connect to Volterra"
}
