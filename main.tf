locals {
  replicaset_name = var.namespace != "" ? "${var.mongodb_replicaset_basename}-${var.namespace}" : "${var.mongodb_replicaset_basename}"
}

resource "random_string" "mongodb_password" {
  length = 20
  special = false
}

resource "random_string" "mongodb_replicaset_key" {
  length = 512
  special = false
}


locals {
  mongodb_password = var.mongodb_password != "" ? var.mongodb_password : random_string.mongodb_password.result
  mongodb_replicaset_key = var.mongodb_replicaset_key != "" ? var.mongodb_replicaset_key : random_string.mongodb_replicaset_key.result
}


data "template_cloudinit_config" "mongodb_replicas" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml",
      {
        replicaset_name = local.replicaset_name
        replicaset_key = local.mongodb_replicaset_key
        replicaset_count = var.replicas_count
        mongodb_image = var.mongodb_image
        admin_password = local.mongodb_password
      }
    )
  }
}

resource "openstack_compute_instance_v2" "mongodb_replicas" {
  count           = var.replicas_count
  name            = "mongodb-${local.replicaset_name}-${count.index + 1}"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.keypair_name
  security_groups = var.security_groups
  user_data = data.template_cloudinit_config.mongodb_replicas.rendered

  network {
    name = var.network_name
  }
}

locals {
  mongodb_replica_ips = [ for node in openstack_compute_instance_v2.mongodb_replicas : node.network.0.fixed_ip_v4]
}

resource "null_resource" "finalize_replicaset" {
  depends_on = [
    openstack_compute_instance_v2.mongodb_replicas,
  ]

  triggers = {
    replica_ips = join(",", local.mongodb_replica_ips)
  }

  connection {
    host        = var.bastion_external_ip
    type        = "ssh"
    user        = var.bastion_user
    port        = var.bastion_port
    private_key = var.bastion_key_pair.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${var.setup_path}",

    ]
  }

  #Setup the replicaset inventory for the playbooks
  provisioner "file" {
    content     = templatefile(
      "${path.module}/files/inventory", 
      {
        replica_ips = local.mongodb_replica_ips
      }
    )
    destination = "${var.setup_path}/inventory"
  }

  provisioner "file" {
    source      = "${path.module}/files/ansible.cfg"
    destination = "${var.setup_path}/ansible.cfg"
  }

  provisioner "file" {
    source      = "${path.module}/files/flag_replicaset_initializer.yml"
    destination = "${var.setup_path}/flag_replicaset_initializer.yml"
  }

  provisioner "file" {
    content      = templatefile(
      "${path.module}/files/hosts-file/hosts",
      {
        replicaset_name = local.replicaset_name
        replica_ips = local.mongodb_replica_ips
      }
    )
    destination  = "${var.setup_path}/hosts"
  }

  provisioner "file" {
    content      = templatefile(
      "${path.module}/files/hosts-file/setup_hosts.yml",
      {
        source = var.setup_path
      }
    )
    destination  = "${var.setup_path}/setup_hosts.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_CONFIG=${var.setup_path}/ansible.cfg ansible-playbook --private-key=/home/${var.bastion_user}/.ssh/id_rsa --user ${var.cluster_user} --inventory ${var.setup_path}/inventory --become --become-user=root ${var.setup_path}/flag_replicaset_initializer.yml",
      "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_CONFIG=${var.setup_path}/ansible.cfg ansible-playbook --private-key=/home/${var.bastion_user}/.ssh/id_rsa --user ${var.cluster_user} --inventory ${var.setup_path}/inventory --become --become-user=root ${var.setup_path}/setup_hosts.yml",
      "sudo rm -r ${var.setup_path}"
    ]
  }
}