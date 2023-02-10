variable "name" {
  description = "Name of the vm"
  type = string
}

variable "image_id" {
    description = "ID of the vm image used to provision the nodes"
    type = string
}

variable "flavor_id" {
  description = "ID of the VM flavor for the nodes"
  type = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used to ssh to the node"
  type = string
}

variable "network_port" {
  description = "Network port to assign to the node. Should be of type openstack_networking_port_v2"
  type        = any
}

variable "server_group" {
  description = "Server group to assign to the node. Should be of type openstack_compute_servergroup_v2"
  type        = any
}

variable "mongodb_server" {
  description = "Parameters that are specific to the mongodb server"
  type = object({
    domain            = string
    bootstrap_cluster = bool
    image             = string
    nameserver_ips    = list(string)
  })
}

variable "mongodb_replicaset" {
  description = "Parameters that are common to the entire mongodb replicaset"
  type = object({
    name           = string
    members        = list(string)
    key            = string
    admin_password = string
  })
}

variable "ca" {
  description = "The ca that will sign the db's certificate. Should have the following keys: key, key_algorithm, certificate"
  type = object({
    key = string
    key_algorithm = string
    certificate = string
  })
  sensitive = true
  default = {
    key = ""
    key_algorithm = ""
    certificate = ""
  }
}

variable "server_certificate" {
  description = "Parameters of the server's certificate. Should contain the following keys: organization, validity_period, early_renewal_period"
  type = object({
    organization = string
    validity_period = number
    early_renewal_period = number
  })
  default = {
    organization = "Ferlab"
    validity_period = 100*365*24
    early_renewal_period = 365*24
  }
}