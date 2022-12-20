data "template_cloudinit_config" "mongodb_replicas" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml",
      {
        nameserver_ips = var.nameserver_ips
        replicaset_name = var.replicaset_name
        replicaset_key = var.replicaset_key
        replicaset_members = var.replicaset_members
        self_domain = var.self_domain
        bootstrap_cluster = var.bootstrap_cluster
        mongodb_image = var.mongodb_image
        admin_password = var.mongodb_admin_password
        tls_certificate = "${tls_locally_signed_cert.certificate.cert_pem}"
        tls_private_key = tls_private_key.key.private_key_pem
        tls_ca_certificate = var.ca.certificate
      }
    )
  }
}

resource "openstack_compute_instance_v2" "mongodb_replica" {
  name            = "${var.self_name}-${var.namespace}"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.keypair_name
  user_data = data.template_cloudinit_config.mongodb_replicas.rendered

  network {
    port = var.network_port.id
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}