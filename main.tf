##############################################################################
# This is default entrypoint.
#  - Ensure user provided region is valid
#  - Ensure user provided resource_group is valid
##############################################################################
terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

provider "ibm" {
  /* Uncomment ibmcloud_api_key while testing from CLI */
  // ibmcloud_api_key = var.api_key
  generation       = 2
  region           = var.region
  ibmcloud_timeout = 300
}

##############################################################################
# Read/validate Region
##############################################################################
data "ibm_is_region" "region" {
  name = var.region
}

# resource group for the VE instance
data "ibm_resource_group" "group" {
  name = var.resource_group
}