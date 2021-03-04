# lookup SSH public keys by name
data "ibm_is_ssh_key" "ssh_pub_key" {
  name = var.ssh_key_name
}

# lookup compute profile by name
data "ibm_is_instance_profile" "instance_profile" {
  name = var.instance_profile
}

# create a random password if we need it
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# lookup image name for a custom image in region if we need it
data "ibm_is_image" "vt_custom_image" {
  name = var.volterra_image_name
}

locals {
  template_file = file("${path.module}/user_data.yaml")
  # user admin_password if supplied, else set a random password
  admin_password = var.volterra_admin_password == "" ? random_password.password.result : var.volterra_admin_password
  # because someone can't spell in the /etc/vpm/certified-hardware.yaml file in the qcow2 image
  certified_hardware_map = {
    voltstack = ["kvm-volstack-combo", "kvm-multi-nic-voltstack-combo"],
    voltmesh = ["kvm-voltmesh","kvm-multi-nic-voltmesh"]
  }
  which_stack = var.volterra_voltstack ? "voltstack" : "voltmesh"
  stack_index = length(local.secondary_subnets) == 1 ? 1 : 0
  inside_nic  = length(local.secondary_subnets) == 1 ? "eth1" : "null"
  certified_hardware = element(local.certified_hardware_map[local.which_stack].*, local.stack_index)
  cluster_name = var.volterra_cluster_name == "" ? "ibm-cloud-${var.region}-${random_uuid.namer.result}" : var.volterra_cluster_name
  fleet_name  = var.volterra_fleet_name == "" ? "null": var.volterra_fleet_name
}

data "template_file" "user_data" {
  template = local.template_file
  vars = {
    admin_password           = local.admin_password
    cluster_name             = local.cluster_name
    fleet_name               = local.fleet_name
    certified_hardware       = local.certified_hardware
    latitude                 = var.site_latitude
    longitude                = var.site_longitude
    site_token               = var.volterra_site_token
    profile                  = var.instance_profile
    inside_nic               = local.inside_nic
  }
}

# create compute instance
resource "ibm_is_instance" "volterra_ce_instance" {
  count          = var.volterra_cluster_size
  name           = "${local.cluster_name}-${count.index}"
  resource_group = data.ibm_resource_group.group.id
  image          = data.ibm_is_image.vt_custom_image.id
  profile        = data.ibm_is_instance_profile.instance_profile.id
  primary_network_interface {
    name              = "external"
    subnet            = data.ibm_is_subnet.external_subnet.id
    security_groups   = [ibm_is_security_group.vt_open_sg.id]
    allow_ip_spoofing = true
  }
  dynamic "network_interfaces" {
    for_each = local.secondary_subnets
    content {
      name              = format("data-1-%d", (network_interfaces.key + 1))
      subnet            = network_interfaces.value
      security_groups   = [ibm_is_security_group.vt_open_sg.id]
      allow_ip_spoofing = true
    }
  }
  vpc        = data.ibm_is_subnet.external_subnet.vpc
  zone       = data.ibm_is_subnet.external_subnet.zone
  keys       = [data.ibm_is_ssh_key.ssh_pub_key.id]
  user_data  = data.template_file.user_data.rendered
  depends_on = [ibm_is_security_group_rule.vt_allow_outbound]
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

resource "ibm_is_floating_ip" "external_floating_ip" {
  count          = var.volterra_cluster_size
  name           = "fip-${var.volterra_cluster_name}-${count.index}"
  resource_group = data.ibm_resource_group.group.id
  target         = element(ibm_is_instance.volterra_ce_instance.*.primary_network_interface.0.id, count.index)
}
