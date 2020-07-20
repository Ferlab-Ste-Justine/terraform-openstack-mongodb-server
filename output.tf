output replicas {
  value = [
    for replica in openstack_compute_instance_v2.mongodb_replicas : {
      id = replica.id
      ip = replica.network.0.fixed_ip_v4
    }
  ]
}

output admin_password {
  value = local.mongodb_password
}