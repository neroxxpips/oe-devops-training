
# Example Terraform Config to create a
# MongoDB Atlas Shared Tier Project, Cluster,
# Database User and Project IP Whitelist Entry
#
# First step is to create a MongoDB Atlas account
# https://docs.atlas.mongodb.com/tutorial/create-atlas-account/
#
# Then create an organization and programmatic API key
# https://docs.atlas.mongodb.com/tutorial/manage-organizations
# https://docs.atlas.mongodb.com/tutorial/manage-programmatic-access
#
# Terraform MongoDB Atlas Provider Documentation
# https://www.terraform.io/docs/providers/mongodbatlas/index.html
# Terraform 0.14+, MongoDB Atlas Provider 0.9.1+

#
#  Local Variables
#  You may want to put these in a variables.tf file
#  Do not check a file containing these variables in a public repository

locals {
  # Replace ORG_ID, PUBLIC_KEY and PRIVATE_KEY with your Atlas variables
  mongodb_atlas_api_pub_key = "PUBLIC_KEY"
  mongodb_atlas_api_pri_key = "PRIVATE_KEY"
  mongodb_atlas_org_id  = "ORG_ID"

  # Replace USERNAME And PASSWORD with what you want for your database user
  # https://docs.atlas.mongodb.com/tutorial/create-mongodb-user-for-cluster/
  mongodb_atlas_database_username = "USERNAME"
  mongodb_atlas_database_user_password = "PASSWORD"

  # Replace IP_ADDRESS with the IP Address from where your application will connect
  # https://docs.atlas.mongodb.com/security/add-ip-address-to-list/
  mongodb_atlas_accesslistip = "IP_ADDRESS"
}

#
# Configure the MongoDB Atlas Provider
#
terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
 }

provider "mongodbatlas" {
  public_key  = local.mongodb_atlas_api_pub_key
  private_key = local.mongodb_atlas_api_pri_key
}

#
# Create a Project
#
resource "mongodbatlas_project" "my_project" {
  name   = "atlasProjectName"
  org_id = local.mongodb_atlas_org_id
}

#
# Create a Shared Tier Cluster
#
resource "mongodbatlas_cluster" "my_cluster" {
  project_id              = mongodbatlas_project.my_project.id
  name                    = "atlasClusterName"

  # Provider Settings "block"
  provider_name = "TENANT"

  # options: AWS AZURE GCP
  backing_provider_name = "AWS"

  # options: M2/M5 atlas regions per cloud provider
  # GCP - CENTRAL_US SOUTH_AMERICA_EAST_1 WESTERN_EUROPE EASTERN_ASIA_PACIFIC NORTHEASTERN_ASIA_PACIFIC ASIA_SOUTH_1
  # AZURE - US_EAST_2 US_WEST CANADA_CENTRAL EUROPE_NORTH
  # AWS - US_EAST_1 US_WEST_2 EU_WEST_1 EU_CENTRAL_1 AP_SOUTH_1 AP_SOUTHEAST_1 AP_SOUTHEAST_2
  provider_region_name = "providerRegionName"

  # options: M2 M5
  provider_instance_size_name = "M2"

  # Will not change till new version of MongoDB but must be included
  mongo_db_major_version = "4.4"
  auto_scaling_disk_gb_enabled = "false"
}

#
# Create an Atlas Admin Database User
#
resource "mongodbatlas_database_user" "my_user" {
  username           = local.mongodb_atlas_database_username
  password           = local.mongodb_atlas_database_user_password
  project_id         = mongodbatlas_project.my_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }
}

#
# Create an IP Accesslist
#
# can also take a CIDR block or AWS Security Group -
# replace ip_address with either cidr_block = "CIDR_NOTATION"
# or aws_security_group = "SECURITY_GROUP_ID"
#
resource "mongodbatlas_project_ip_access_list" "my_ipaddress" {
      project_id = mongodbatlas_project.my_project.id
      ip_address = local.mongodb_atlas_accesslistip
      comment    = "My IP Address"
}

