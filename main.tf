data "template_cloudinit_config" "mongodb_server" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml",
      {
        mongodb_server = var.mongodb_server
        mongodb_replicaset = var.mongodb_replicaset
        tls_certificate = "${tls_locally_signed_cert.certificate.cert_pem}"
        tls_private_key = tls_private_key.key.private_key_pem
        tls_ca_certificate = var.ca.certificate
      }
    )
  }
}

resource "openstack_compute_instance_v2" "mongodb_server" {
  name            = var.name
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.keypair_name
  user_data = data.template_cloudinit_config.mongodb_server.rendered

  network {
    port = var.network_port.id
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}