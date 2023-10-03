locals {
  fluentd_port   = 28080
  fluentd_params = var.fluentd.enabled ? "--log-driver=fluentd --log-opt fluentd-address=127.0.0.1:${local.fluentd_port} --log-opt fluentd-async-connect=true --log-opt fluentd-retry-wait=1s --log-opt fluentd-max-retries=3600 --log-opt fluentd-sub-second-precision=true --log-opt tag=${var.fluentd.mongodb_tag}" : ""
  block_devices  = var.image_source.volume_id != "" ? [{
    uuid                  = var.image_source.volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }] : []
  cloudinit_templates = concat(
    [{
      filename     = "mongodb.cfg"
      content_type = "text/cloud-config"
      content      = templatefile(
        "${path.module}/files/cloud_config.yaml",
        {
          mongodb_server     = var.mongodb_server
          mongodb_replicaset = var.mongodb_replicaset
          tls_certificate    = "${tls_locally_signed_cert.certificate.cert_pem}"
          tls_private_key    = tls_private_key.key.private_key_pem
          tls_ca_certificate = var.ca.certificate
          fluentd_params     = local.fluentd_params
        }
      )
    }],
    var.fluentd.enabled ? [{
      filename     = "fluentd.cfg"
      content_type = "text/cloud-config"
      content      = module.fluentd_configs.configuration
    }] : []
  )
}

module "fluentd_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//fluentd?ref=v0.13.1"
  install_dependencies = true
  fluentd              = {
    docker_services        = [
      {
        tag                = var.fluentd.mongodb_tag
        service            = "mongodb"
        local_forward_port = local.fluentd_port
      }
    ]
    systemd_services = [
      {
        tag     = var.fluentd.node_exporter_tag
        service = "node-exporter"
      }
    ]
    forward = var.fluentd.forward,
    buffer  = var.fluentd.buffer
  }
}

data "template_cloudinit_config" "mongodb_server" {
  gzip = true
  base64_encode = true
  dynamic "part" {
    for_each = local.cloudinit_templates
    content {
      filename     = part.value["filename"]
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
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