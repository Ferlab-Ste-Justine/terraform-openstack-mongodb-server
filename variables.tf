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

variable "security_groups" {
  description = "Security groups of the nodes"
  type = list(string)
  default = ["default"]
}

variable "network_name" {
  description = "Name of the network the nodes will be attached to"
  type = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used to ssh on the mongodb replicas"
  type = string
}

variable "replicas_count" {
  description = "Number of replicas in the replicaset"
  type = number
  default = 3
}

variable "bastion_external_ip" {
  description = "External ip of the bastion"
  type = string
}

variable "bastion_port" {
  description = "Ssh port the bastion uses"
  type = number
  default = 22
}

variable "bastion_user" {
  description = "User to ssh on the bastion as"
  type = string
  default = "ubuntu"
}

variable "bastion_key_pair" {
  description = "SSh key pair"
  type = any
}

variable "cluster_user" {
  description = "User to ssh on the replicas from the bastion as"
  type = string
  default = "ubuntu"
}

variable "setup_path" {
  description = "Directory to put ansible files under"
  type = string
}

variable "mongodb_image" {
  description = "Name of the docker image that will be used to provision mongodb"
  type = string
  default = "mongo:4.2.13"
}

variable "mongodb_password" {
  description = "Password of the admin user. If no value is provided, a random value will be generated"
  type = string
  default = ""
}

variable "mongodb_replicaset_key" {
  description = "Key used by replicaset members to authentify each other"
  type = string
  default = ""
}

variable "mongodb_replicaset_basename" {
  description = "Base name to give to the replicaset when declaring it"
  type = string
  default = "replicaset"
}