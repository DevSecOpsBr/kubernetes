# Motivation

It's been a while since my last article here! I was missing writing and sharing my experience on how I figured out and manage to have a Kubernetes multi-node cluster running on macOS M1 without Virtualbox, Parallel, VMWare, Docker-Desktop, TUM and etc...

I used to have a multi-node cluster on a macOS Intel processor running in Virtualbox. Nowadays, with the new apple M1 chips, there is no way to have Virtualbox!  So I find out about the amazing Lima-VM project with ARM support check it out below!

## Pre-reqs

* Lima-vm: lima-vm/lima
* lima-vm/vde_vmnet: lima-vm/vde_vmnet
* k3s: k3s.io

## Bringing the cluster to live!

I have created a simple shell script to manage the token creation and join control-planes and nodes to the cluster. 


PS: The shell script is not the focus but just a simple way to create lima-vms and the cluster.  

## Caveats

Networking: I have configured the Kubernetes cluster to use my LAN networks, which means, the cluster is accessible to all devices/computers on your LAN.
DNS: I needed to tell to kubelet to read K3S_RESOLV_CONF=/run/systemd/resolve/resolv.conf instead of /etc/resolv.conf. Reference: known-issues

Cluster is alive

```(shell)
NAME             STATUS   ROLES                       AGE     VERSION        INTERNAL-IP     EXTERNAL-IP     OS-IMAGE           KERNEL-VERSION      CONTAINER-RUNTIME
lima-manager-1   Ready    control-plane,etcd,master   5m27s   v1.22.8+k3s1   192.168.2.101   192.168.2.101   Ubuntu 22.04 LTS   5.15.0-37-generic   containerd://1.5.10-k3s1
lima-manager-2   Ready    control-plane,etcd,master   2m26s   v1.22.8+k3s1   192.168.2.102   192.168.2.102   Ubuntu 22.04 LTS   5.15.0-37-generic   containerd://1.5.10-k3s1
lima-node-1      Ready    <none>                      85s     v1.22.8+k3s1   192.168.2.230   192.168.2.230   Ubuntu 22.04 LTS   5.15.0-37-generic   containerd://1.5.10-k3s1
lima-node-2      Ready    <none>                      46s     v1.22.8+k3s1   192.168.2.218   192.168.2.218   Ubuntu 22.04 LTS   5.15.0-37-generic   containerd://1.5.10-k3s1
lima-node-3      Ready    <none>                      4s      v1.22.8+k3s1   192.168.2.219   192.168.2.219   Ubuntu 22.04 LTS   5.15.0-37-generic   containerd://1.5.10-k3s1
```

Have you linked? Then go ahead and clone or fork the repo.

See you in the next one.

