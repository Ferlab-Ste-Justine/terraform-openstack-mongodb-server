# About

This module provision a mongodb replicaset. Mondodb will run inside a container on each node.

Originally, this module orchestrated the entire replicaset, but for maintenance reasons, it has been refactored to provision a single instance in a replicaset so this module needs to be invoked for each replicaset instance.

# Dependencies

This module has been validated against recent versions of **Ubuntu** (20.04) for the base image. Your mileage may vary with other distributions.

This module also assumes the existance of a nameserver to manage your mongodb domains and an internal certificate authority which is used to provision certificates.

# Variables

The module takes the following variables as input.

- **namespace**: Namespace to isolate the generate resources. It will be suffixed to the name of the generated resources in openstack.
- **image_id**: ID of the vm image used to provision the node.
- **flavor_id**: ID of the VM flavor for the node.
- **network_port**: Network port to assign to the node. Should be of type openstack_networking_port_v2.
- **keypair_name**: Ssh key that will be used by the bastion to ssh on the node.
- **self_name**: Base name of the vm that will be defined in openstack.
- **self_domain**: Externally accessible domain of the vm. The hostname of the vm will be assigned to that domain as well.
- **replicaset_members**: List of externally accessible domain names for all the replicaset nodes (one per node)
- **replicaset_key**: Key used by replicaset members to authentify each other
- **replicaset_name**: Name to give to the replicaset when declaring it. Defaults to **replicaset**
- **nameserver_ips**: Ips of nameservers that should be used by the node to resolve domains.
- **bootstrap_cluster**: Whether the node should bootstrap the cluster: Configuring the replicaset and admin user. This is a boolean that defaults to false.
- **mongodb_image**: Name of the docker image that will be used to provision mongodb
- **mongodb_admin_password**: Password that will be used for the admin user
- **ca**: The ca that will sign the db's certificate. Should have the following keys: key, key_algorithm, certificate
- **organization**: The mongodb server certificates' organization
- **certificate_validity_period**: The mongodb server cluster's certificate's validity period in hours. Defaults to 100 years.
- **certificate_early_renewal_period**: The mongodb server cluster's certificate's validity period in hours. Defaults to 99 years.
- **key_length**: The key length of the certificate's RSA private key. Defaults to 4096.

# Example

```
module "ca" {
  source = "./ca"
}

resource "random_string" "mongodb_admin_password" {
  length = 128
  special = false
}
resource "random_string" "mongodb_replicaset_key" {
  length = 512
  special = false
}

resource "openstack_compute_keypair_v2" "mongodb" {
  name = "mongodb-test"
}

module "mongodb_security_groups" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-mongodb-security-groups.git"
  namespace = "test"
}

resource "openstack_networking_port_v2" "mongodb" {
  count          = 3
  name           = "mongodb-test-${count.index + 1}"
  network_id     = module.reference_infra.networks.internal.id
  security_group_ids = [module.mongodb_security_groups.groups.replicaset_member.id]
  admin_state_up = true
}

module "mondodb_replica_1" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-mongodb-replicaset.git"
  namespace = "test"
  image_id = data.openstack_images_image_v2.ubuntu_focal.id
  flavor_id = module.reference_infra.flavors.nano.id
  network_port = openstack_networking_port_v2.mongodb.0
  self_name = "mongodb-replica-1"
  self_domain = "replica-1.putyourdomain.com"
  keypair_name = openstack_compute_keypair_v2.mongodb.name
  replicaset_members = [
      "replica-1.putyourdomain.com",
      "replica-2.putyourdomain.com",
      "replica-3.putyourdomain.com"
  ]
  nameserver_ips = local.dns_ops.nameserver_ips
  bootstrap_cluster = true
  mongodb_admin_password = random_string.mongodb_admin_password.result
  replicaset_key = random_string.mongodb_replicaset_key.result
  ca = module.ca
}

module "mondodb_replica_2" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-mongodb-replicaset.git"
  namespace = "test"
  image_id = data.openstack_images_image_v2.ubuntu_focal.id
  flavor_id = module.reference_infra.flavors.nano.id
  network_port = openstack_networking_port_v2.mongodb.1
  self_name = "mongodb-replica-2"
  self_domain = "replica-2.putyourdomain.com"
  keypair_name = openstack_compute_keypair_v2.mongodb.name
  replicaset_members = [
      "replica-1.putyourdomain.com",
      "replica-2.putyourdomain.com",
      "replica-3.putyourdomain.com"
  ]
  nameserver_ips = local.dns_ops.nameserver_ips
  bootstrap_cluster = false
  mongodb_admin_password = random_string.mongodb_admin_password.result
  replicaset_key = random_string.mongodb_replicaset_key.result
  ca = module.ca
}

module "mondodb_replica_3" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-mongodb-replicaset.git"
  namespace = "test"
  image_id = data.openstack_images_image_v2.ubuntu_focal.id
  flavor_id = module.reference_infra.flavors.nano.id
  network_port = openstack_networking_port_v2.mongodb.2
  self_name = "mongodb-replica-3"
  self_domain = "replica-3.putyourdomain.com"
  keypair_name = openstack_compute_keypair_v2.mongodb.name
  replicaset_members = [
      "replica-1.putyourdomain.com",
      "replica-2.putyourdomain.com",
      "replica-3.putyourdomain.com"
  ]
  nameserver_ips = local.dns_ops.nameserver_ips
  bootstrap_cluster = false
  mongodb_admin_password = random_string.mongodb_admin_password.result
  replicaset_key = random_string.mongodb_replicaset_key.result
  ca = module.ca
}


module "k8_external_domain" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-zonefile.git"
  domain = "putyourdomain.com"
  cache_ttl = 3600
  container = local.dns_ops.bucket_name
  dns_server_name = "ns.putyourdomain.com."
  a_records = [
    {
      prefix = "replica-1"
      ip = openstack_networking_port_v2.mongodb.0.all_fixed_ips.0
    },
    {
      prefix = "replica-2",
      ip = openstack_networking_port_v2.mongodb.1.all_fixed_ips.0
    },
    {
      prefix = "replica-3",
      ip = openstack_networking_port_v2.mongodb.2.all_fixed_ips.0
    }
  ]
}

```

# Gotcha

To safeguard against potential outages and loss of data, changes to the server's user data will be ignored without reprovisioning.

To reprovision a new instance with changes to the following parameters, the module should be explicitly deleted and re-created:
- nameserver_ips
- replicaset_name
- replicaset_key
- replicaset_members
- self_domain
- bootstrap_cluster
- mongodb_image
- mongodb_admin_password
- ca
- organization
- certificate_validity_period
- certificate_early_renewal_period
- key_length