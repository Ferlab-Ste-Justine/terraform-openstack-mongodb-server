# About

This module provision a mongodb replicaset. Mondodb will run inside a container on each node.

Originally, this module orchestrated the entire replicaset, but for maintenance reasons, it has been refactored to provision a single instance in a replicaset so this module needs to be invoked for each replicaset instance.

# Dependencies

This module has been validated against recent versions of **Ubuntu** (20.04) for the base image. Your mileage may vary with other distributions.

This module also assumes the existance of a nameserver to manage your mongodb domains and an internal certificate authority which is used to provision certificates.

# Variables

The module takes the following variables as input.

- **name**: Name of the vm.
- **image_source**: Source of the image to provision the node on. It takes the following keys (only one of the two fields should be used, the other one should be empty):
  - **image_id**: Id of the image to associate with a vm that has local storage
  - **volume_id**: Id of a volume containing the os to associate with the vm
- **flavor_id**: ID of the VM flavor for the node.
- **network_port**: Network port to assign to the node. Should be of type openstack_networking_port_v2.
- **server_group**: Server group to assign to the node. Should be of type openstack_compute_servergroup_v2.
- **keypair_name**: Ssh key that will be used by the bastion to ssh on the node.
- **mongodb_server**: Parameters that are specific to the mongodb server. It has the following keys:
  - **domain**: Externally accessible domain of the vm. The server certificate will be signed for that domain and the hostname of the vm will be assigned to that domain as well.
  - **bootstrap_cluster**: Whether the node should bootstrap the cluster: Configuring the replicaset and admin user. Only one node in the replicaset should have this value set to true and only when the replicaset is initially provisioned.
  - **image**: Docker image to use for mongodb. Version 4 of mongodb is recommended as this is the version this module was validated with so far.
  - **nameserver_ips**: Ips of nameservers that will resolve the vm's domain. Will be added at the end of the os nameservers list for the vm. Can be an empty array if the nameservers the vm will point to already correctly resolve the domain.
- **mongodb_replicaset**: Parameters that are common to the entire mongodb replicaset. It has the following keys:
  - **name**: Name to give to the replicaset when declaring it. 
  - **members**: List of externally accessible domain names for all the replicaset nodes (one per node)
  - **key**: Key used by replicaset members to authentify each other
  - **admin_password**: Password that will be used for the admin user
- **ca**: Parameters of the server's certificate. Should contain the following keys: organization, validity_period, early_renewal_period
- **server_certificate**: Parameters for the server certificate. It has the following keys:
  - **organization**: The mongodb server certificates' organization
  - **validity_period**: The mongodb server cluster's certificate's validity period in hours.
  - **early_renewal_period**: The mongodb server cluster's certificate's validity period in hours.
- **fluentd**: Optional fluentd configuration to securely route logs to a fluentd node using the forward plugin. It has the following keys:
  - **enabled**: If set to false (the default), fluentd will not be installed.
  - **mongodb_tag**: Tag to assign to logs coming from mongodb
  - **node_exporter_tag** Tag to assign to logs coming from the prometheus node exporter
  - **forward**: Configuration for the forward plugin that will talk to the external fluentd node. It has the following keys:
    - **domain**: Ip or domain name of the remote fluentd node.
    - **port**: Port the remote fluentd node listens on
    - **hostname**: Unique hostname identifier for the vm
    - **shared_key**: Secret shared key with the remote fluentd node to authentify the client
    - **ca_cert**: CA certificate that signed the remote fluentd node's server certificate (used to authentify it)
  - **buffer**: Configuration for the buffering of outgoing fluentd traffic
    - **customized**: Set to false to use the default buffering configurations. If you wish to customize it, set this to true.
    - **custom_value**: Custom buffering configuration to provide that will override the default one. Should be valid fluentd configuration syntax, including the opening and closing ```<buffer>``` tags.

# Example

```
locals {
  cluster = [
    {
      name              = "server-1"
      enabled           = true
      flavor            = module.reference_infra.flavors.nano.id
      image             = data.openstack_images_image_v2.ubuntu_focal.id
      mongodb_image     = "mongo:4.4.18"
      domain            = "server-1.myproject.com"
      bootstrap_cluster = true
    },
    {
      name              = "server-2"
      enabled           = true
      flavor            = module.reference_infra.flavors.nano.id
      image             = data.openstack_images_image_v2.ubuntu_focal.id
      mongodb_image     = "mongo:4.4.18"
      domain            = "server-2.myproject.com"
      bootstrap_cluster = false
    },
    {
      name              = "server-3"
      enabled           = true
      flavor            = module.reference_infra.flavors.nano.id
      image             = data.openstack_images_image_v2.ubuntu_focal.id
      mongodb_image     = "mongo:4.4.18"
      domain            = "server-3.myproject.com"
      bootstrap_cluster = false
    }
  ]
}

module "ca" {
  source = "./ca"
}

resource "random_password" "mongodb_admin_password" {
  length  = 100
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "random_password" "mongodb_replicaset_key" {
  length  = 512
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "openstack_compute_keypair_v2" "mongodb" {
  name = "myproject-mongodb"
}

module "mongodb_security_groups" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-mongodb-security-groups.git"
  namespace = "myproject"
}

resource "openstack_compute_servergroup_v2" "mongodb" {
  name     = "myproject-mongodb"
  policies = ["soft-anti-affinity"]
}

resource "openstack_networking_port_v2" "mongodb" {
  for_each = {
    for server in local.cluster : server.name => server
  }

  name               = "myproject-mongodb-${each.value.name}"
  network_id         = module.reference_infra.networks.internal.id
  security_group_ids = [module.mongodb_security_groups.groups.replicaset_member.id]
  admin_state_up     = true
}

module "mondodb_vms" {
  for_each = {
    for server in local.cluster : server.name => server if server.enabled
  }

  source = "git::https://github.com/Ferlab-Ste-Justine/terraform-openstack-mongodb-server.git"
  name               = "myproject-mongodb-${each.value.name}"
  image_source = {
    image_id  = each.value.image
    volume_id = ""
  }
  flavor_id          = each.value.flavor
  network_port       = openstack_networking_port_v2.mongodb[each.value.name]
  server_group       = openstack_compute_servergroup_v2.mongodb
  keypair_name       = openstack_compute_keypair_v2.mongodb.name
  ca                 = module.ca
  mongodb_server     = {
    domain            = each.value.domain
    bootstrap_cluster = each.value.bootstrap_cluster
    image             = each.value.mongodb_image
    nameserver_ips    = local.my_dns_servers.ips
  }
  mongodb_replicaset = {
    name             = "myproject-mongodb"
    members          = [
      "server-1.myproject.com",
      "server-2.myproject.com",
      "server-3.myproject.com"
    ]
    key              = random_password.mongodb_replicaset_key.result
    admin_password   = random_password.mongodb_admin_password.result
  }
}

module "mongodb_domain" {
  source = "git::https://github.com/Ferlab-Ste-Justine/terraform-openstack-zonefile.git"
  domain = "myproject.com"
  cache_ttl = 3600
  container = local.dns.bucket_name
  dns_server_name = "ns.myproject.com."
  a_records = [
    for server in local.cluster: {
      prefix = server.name
      ip     = openstack_networking_port_v2.mongodb[server.name].all_fixed_ips.0
    }
  ]
}

```

# Gotcha

To safeguard against potential outages and loss of data, changes to the server's user data will be ignored without reprovisioning.

To make sure changes, you should explicitly decommission and recommission the affected vms.