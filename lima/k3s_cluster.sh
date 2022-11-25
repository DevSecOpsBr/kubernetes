#!/bin/bash

set -e
set -o noglob

MANAGER_FILE="k3s_manager.yaml"
NODE_FILE="k3s_nodes.yaml"
K3S_TOKEN="K3S_TOKEN=$(openssl rand -hex 12)"
IFACE="bridged"
VERSION='v1.22.8+k3s1'
LIMACTL=$(which limactl)

CLUSTER_NAME=$1
MANAGER_NODES=$2
WORKER_NODES=$3

main() {

  is_num='^[0-9]+$'

  if ! [[ $CLUSTER_NAME =~ $is_num ]]; then
    echo -e "Here is what I am going to do        \n"
    echo -e "Creating cluster: $CLUSTER_NAME     🚀 \n"
    echo -e "Control-planes:  $MANAGER_NODES      🎛️ \n"
    echo -e "Nodes: $WORKER_NODES                📺 \n"

    deploy_masters

  else
    echo "‼️  You must specify a valid cluster name  ‼️"
    echo '💡 ./k3s_cluster.sh <cluster-name> <num-manager> <num-nodes> 📌'
    exit 101
  fi

}

deploy_masters() {

  MASTER_INIT="INSTALL_K3S_VERSION=${VERSION} K3S_LB_SERVER_PORT=6444 K3S_RESOLV_CONF=\/run\/systemd\/resolve\/resolv.conf INSTALL_K3S_EXEC=--cluster-init"
  ADVERTISE='--node-external-ip ${LIMA0} --node-ip ${LIMA0} --bind-address ${LIMA0} --tls-san ${LIMA0} -flannel-iface ${IFACE} --disable=traefik --disable=servicelb --node-label ingress=controller'

  for ((m=1;m<=$MANAGER_NODES;m++));
    do
        if [ $m -eq 1 ]; then
          echo "Creating manager node $m ...... 🔄"
          sed -e "s/__IFACE__/${IFACE}/" -e "s/__TOKEN__/${K3S_TOKEN}/" -e "s/__REPLACEME__/${MASTER_INIT}/" -e "s/__ADVERTISEME__/${ADVERTISE}/" $MANAGER_FILE > $m-$MANAGER_FILE
          $LIMACTL validate $m-$MANAGER_FILE
          if [[ $? -eq 0 ]]; then
            echo "Template is valid ..."
            $LIMACTL start --name manager-$m $m-$MANAGER_FILE
            echo "Manager node created: $m ...... ✅"
          else
            echo "Template is not valid!"
            exit 404
          fi
          echo "Manager node created: $m"
          $LIMACTL shell manager-$m sudo kubectl get nodes -owide

          echo "Exporting kubeconfig file ...... ⚙️"
          KUBECONFIG="$HOME/.kube/$CLUSTER_NAME.yaml"
          limactl shell manager-$m sudo kubectl config rename-context default $CLUSTER_NAME
          limactl shell manager-$m sudo cat /etc/rancher/k3s/k3s.yaml > $KUBECONFIG

          echo "Gathering manager information ...... ⚙️"
          sleep 15
          MANAGER_IPADDR=$(limactl shell manager-$m sudo kubectl get nodes -owide | grep "192.168." | awk '{print $6}')
          MANAGERS_JOIN="INSTALL_K3S_VERSION=${VERSION} INSTALL_K3S_EXEC=server K3S_URL=https:\/\/${MANAGER_IPADDR}:6443"
        fi

        if [ $m -gt 1 ]; then
          echo "Creating remaining manager nodes $m ..."
          sed -e "s/__IFACE__/${IFACE}/" -e "s/__TOKEN__/${K3S_TOKEN}/" -e "s/__REPLACEME__/${MANAGERS_JOIN}/" -e "s/__ADVERTISEME__/${ADVERTISE}/" $MANAGER_FILE > $m-$MANAGER_FILE
          $LIMACTL validate $m-$MANAGER_FILE
          if [[ $? -eq 0 ]]; then
            echo "Template is valid ...... ✅"
            $LIMACTL start --name manager-$m $m-$MANAGER_FILE
            echo "Manager node created: $m"
          else
            echo "Template is not valid!"
            exit 404
          fi
          echo "Manager node created: $m"
          $LIMACTL shell manager-$m sudo kubectl get nodes -owide
        fi
    done

  deploy_nodes

}

deploy_nodes() {

  MANAGER_IPADDR=$(limactl shell manager-1 ip addr show lima0 |egrep 'inet '| awk '{print $2}'| cut -d '/' -f1)
  NODE_JOIN="INSTALL_K3S_VERSION=${VERSION} K3S_RESOLV_CONF=\/run\/systemd\/resolve\/resolv.conf K3S_URL=https:\/\/${MANAGER_IPADDR}:6443"
  ADVERTISE='--node-external-ip ${LIMA0} --node-ip ${LIMA0} -flannel-iface ${IFACE}'

  for ((n=0;n<=$WORKER_NODES;n++));
    do
      if [ $n -ge 1 ]; then
        echo "Creating nodes $n ...... 🔄"
        sed -e "s/__IFACE__/${IFACE}/" -e "s/__TOKEN__/${K3S_TOKEN}/" -e "s/__REPLACEME__/${NODE_JOIN}/" -e "s/__ADVERTISEME__/${ADVERTISE}/" $NODE_FILE > $n-$NODE_FILE
        $LIMACTL validate $n-$NODE_FILE
        if [[ $? -eq 0 ]]; then
          echo "Template is valid ...... ✅"
          $LIMACTL start --name node-$n $n-$NODE_FILE
          echo "Node node created: $n"
        else
          echo "Template is not valid!"
          exit 404
        fi
        echo "Node created: $n ...... ✅"
        $LIMACTL shell manager-1 sudo kubectl get nodes -owide
      fi
  done

  cleanUp

}

cleanUp() {

  for i in {1..3}
    do
      rm -f $i-$NODE_FILE
      rm -f $i-$MANAGER_FILE
  done

}

main
