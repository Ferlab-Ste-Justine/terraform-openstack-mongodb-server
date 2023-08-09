locals {
  block_devices = var.image_source.volume_id != "" ? [{
    uuid                  = var.image_source.volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }] : []
}

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
  name      = var.name
  image_id  = var.image_source.image_id != "" ? var.image_source.image_id : null
  flavor_id = var.flavor_id
  key_pair  = var.keypair_name
  user_data = data.template_cloudinit_config.mongodb_server.rendered

  scheduler_hints {
    group = var.server_group.id
  }

  network {
    port = var.network_port.id
  }

  dynamic "block_device" {
    for_each = local.block_devices
    content {
      uuid                  = block_device.value["uuid"]
      source_type           = block_device.value["source_type"]
      boot_index            = block_device.value["boot_index"]
      destination_type      = block_device.value["destination_type"]
      delete_on_termination = block_device.value["delete_on_termination"]
    }
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}