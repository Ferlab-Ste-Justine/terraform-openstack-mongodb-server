# About

This module provision a mongodb replicaset. Mondodb will run inside a container on each node.

# Dependencies

This module has been validated against recent versions of **Ubuntu** for the base image. Your mileage may vary with other distributions.

Furthermore, this module currently requires a bastion for provisioning (will be remedied in the future, but it is the current state of things).

# Limitations

The replicaset is currently setup without tls.

All nodes in a replicaset are currently provisioned together in single module, so updates will produce downtime and require a backup/restore strategy.

Because dns is done via the **host** file in all members of the replicaset, changing the size of the replicaset is not really an option (it will cause the nodes to be reprovisioned). However, it is probably not quite as annoying as the other two limitations as you seldom want to change the size of a replicaset (if you want real scalability, **sharding** is the way to go and its out of scope for this module right now).

# Variables

The module takes the following variables as input.

- **namespace**: Namespace to isolate the generate resources. The replicaset will be named ```<mongodb_replicaset_basename>-<namespace>``` and the nodes will be named ```<mongodb_replicaset_basename>-<node-number>-<namespace>```. Can be omitted.
- **mongodb_replicaset_basename**: Basename of the replicaset. See description of **namespace** above for details. Defaults to **replicaset**.
- **image_id**: ID of the vm image used to provision the nodes
- **flavor_id**: ID of the VM flavor for the nodes
- **security_groups**: Security groups to assign to the members of the replicaset.
- **network_name**: Name of the openstack network that the replicaset members will be attached to.
- **keypair_name**: Ssh key that will be used by the bastion to ssh on any server of the replicaset.
- **replicas_count**: Numbers of replicas in the replicaset. Should not be changed once the cluster is created. Defaults to 3.
- **bastion_external_ip**: Externally accessible ip for the bastion. Will be used by terraform to finalize the replicaset configuration via **ansible** scripts.
- **bastion_port**: Bastion port that is open for ssh. Defaults to **22**. Will be used by terraform to finalize the replicaset configuration via **ansible** scripts.
- **bastion_user**: User to ssh on the bastion as. Defaults to **ubuntu**. Will be used by terraform to finalize the replicaset configuration via **ansible** scripts.
- **bastion_key_pair**: ssh keypair that will be used to ssh on the bastion. Will be used by terraform to finalize the replicaset configuration via **ansible** scripts.
- **cluster_user**: User that ansible will use to ssh into each replica from the bastion.
- **Directory to put ansible files under**: Directory where ansible files will be put on the bastion.
- **mongodb_image**: Name of the docker image that will be used to provision mongodb. Defaults to **mongo:4.2**.
- **mongodb_password**: Password of the admin user. If no value is provided, a random value will be generated
- **mongodb_replicaset_key**: Key used by replicaset members to authentify each other

# Output

The module provides the following variables as output:

- **replicas**: Array of replicas, each containing two keys: **ip** (if of the replica) and **id** (id of the vm the replica runs on)
- **admin_password**: Password of the admin user.



