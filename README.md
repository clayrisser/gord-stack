# gord-stack

A stack for managing a highly available cloud platform.

GORD stands for . . .

### Glusterfs
Glusterfs is used to maintain persistent storage accross the GORD stack.
### Object Store
Object Store is used to keep the applications on the GORD stack safely backed up. The GORD stack uses duplicati to manage the backups. Most major cloud providers are supported.
### Rancher
Rancher is the orchastration platform. It is used to keep a scalable and highly availble platform.
### Docker
Docker is the contianer engine. Any application packaged as a docker container can be run on the GORD stack.

## Installation

The GORD stack requires a minimum of three servers. One server runs the orchastration platform. The rest of the servers are nodes. They run the GORD stack applications. You must have at least 2 nodes.

#### Prepare orchastration server
The orchastration server must be Ubuntu 16.04.
SSH into the orchastration server and run the following command.

```
wget https://raw.githubusercontent.com/jamrizzi/gord-stack/master/orchestrator.sh && sudo bash orchestrator.sh
```

If you want your orchastration platform backed up, go to port orchestrator-server:8080 and create a backup for /var/lib/mysql/ 

#### Prepare rancher

Create an environment in rancher and spin up some hosts. These hosts will be your nodes.

#### Prepare nodes

On all of your nodes, run the following command.

```
wget https://raw.githubusercontent.com/jamrizzi/gord-stack/master/node.sh && sudo bash node.sh
```

#### Prepare master-node

One of your nodes is the master node. Run the following on that server.

```
wget https://raw.githubusercontent.com/jamrizzi/gord-stack/master/master-node.sh && sudo bash master-node.sh
```

## Notes

This has only been tested on Google Cloud.
