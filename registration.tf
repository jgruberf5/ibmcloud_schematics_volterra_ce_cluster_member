
resource "null_resource" "volterra_lifecycle" {

  triggers = {
    site                = local.cluster_name,
    tenant              = var.volterra_tenant
    token               = var.volterra_api_token
    size                = var.volterra_cluster_size,
    allow_ssl_tunnels   = var.volterra_ssl_tunnels ? "true" : "false"
    allow_ipsec_tunnels = var.volterra_ipsec_tunnels ? "true" : "false"
    nodes               = join(",", ibm_is_instance.volterra_ce_instance.*.name)
  }

  depends_on = [ibm_is_instance.volterra_ce_instance]

  provisioner "local-exec" {
    when        = create
    command     = "${path.module}/site_registration_actions.py --delay 60 --action 'registernodes' --site '${self.triggers.site}' --tenant '${self.triggers.tenant}' --token '${self.triggers.token}' --ssl ${self.triggers.allow_ssl_tunnels} --ipsec ${self.triggers.allow_ipsec_tunnels} --size ${self.triggers.size}"
    on_failure  = continue
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/site_registration_actions.py --action deleteregistrations --site '${self.triggers.site}' --tenant '${self.triggers.tenant}' --token '${self.triggers.token}' --nodes '${self.triggers.nodes}' --size ${self.triggers.size}"
    on_failure  = continue
  }
}
resource "local_file" "complete_flag" {
  filename   = "${path.module}/complete.flag"
  content    = random_uuid.namer.result
  depends_on = [null_resource.volterra_lifecycle]
}
