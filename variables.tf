variable "namespace" {
  description = "Namespace to create the resources under"
  type = string
  default = ""
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

variable "self_name" {
  description = "Base name of the vm"
  type = string
}

variable "self_domain" {
  description = "Domain name of the vm"
  type = string
}

variable "replicaset_members" {
  description = "List of domain names indicating the members of the replicaset"
  type        = list(string)
}

variable "replicaset_key" {
  description = "Key used by replicaset members to authentify each other"
  type = string
}

variable "replicaset_name" {
  description = "Name to give to the replicaset when declaring it"
  type = string
  default = "replicaset"
}

variable "nameserver_ips" {
  description = "Ips of the nameservers"
  type = list(string)
  default = []
}

variable "bootstrap_cluster" {
  description = "Whether the node should bootstrap the cluster: Configuring the replicaset and admin user"
  type        = bool
  default     = false
}

variable "mongodb_image" {
  description = "Name of the docker image that will be used to provision mongodb"
  type = string
  default = "mongo:4.2.13"
}

variable "mongodb_admin_password" {
  description = "Password of the admin user"
  type = string
}

variable "ca" {
  description = "The ca that will sign the db's certificate. Should have the following keys: key, key_algorithm, certificate"
  type = any
}

variable "organization" {
  description = "The mongodb server certificates' organization"
  type = string
  default = "Ferlab"
}

variable "certificate_validity_period" {
  description = "The mongodb server cluster's certificate's validity period in hours"
  type = number
  default = 100*365*24
}

variable "certificate_early_renewal_period" {
  description = "The mongodb server cluster's certificate's early renewal period in hours"
  type = number
  default = 365*24
}

variable "key_length" {
  description = "The key length of the certificate's private key"
  type = number
  default = 4096
}
