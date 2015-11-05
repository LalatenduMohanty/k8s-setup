#!/bin/bash

function k8s_config_usage ()
{
  echo "$0 {clean}"
}

function single_node_setup ()
{

    #check if the service account key for kube services is correctly set
    if ! [ grep 'serviceaccount.key' /etc/kubernetes/apiserver >/dev/null 2>&1 ] && \
      [ /etc/kubernetes/controller-manager >/dev/null 2>&1 ]; then
        setup_kube_service_account_key
    fi
    
    #enable Kubernetes master services
    #etcd kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler
    
    #enable Kubernetes minion services
    #kube-proxy kubelet docker

    sudo systemctl enable kube-proxy kubelet
    sudo systemctl start kube-proxy kubelet
    sudo systemctl restart docker
    

}

function setup_kube_service_account_key()
{
    sudo mkdir -p /etc/pki/kube-apiserver/
    sudo openssl genrsa -out /etc/pki/kube-apiserver/serviceaccount.key 2048

    sudo sed -i.back '/KUBE_API_ARGS=*/c\KUBE_API_ARGS="--service_account_key_file=/etc/pki/kube-apiserver/serviceaccount.key"' /etc/kubernetes/apiserver

    sudo sed -i.back '/KUBE_CONTROLLER_MANAGER_ARGS=*/c\KUBE_CONTROLLER_MANAGER_ARGS="--service_account_private_key_file=/etc/pki/kube-apiserver/serviceaccount.key"' /etc/kubernetes/controller-manager

}

function clean_setup ()
{
    echo "Stopping the Kubernetes services"
    
    #enable Kubernetes master services
    #etcd kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl disable etcd kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl stop etcd kube-apiserver kube-controller-manager kube-scheduler
    
    #enable Kubernetes minion services
    #kube-proxy kubelet docker

    sudo systemctl disable kube-proxy kubelet
    sudo systemctl stop kube-proxy kubelet

}

function k8s_config()
{

    { test "z$1" = "z--help"; } && { k8s_config_usage; return 255; }

    local option1=$1
    if [ -z "${option1}" ];then
        echo "Setting the host as both k8s master and node"
        single_node_setup
    elif [ ${option1} = "clean" ];then
        echo "Cleaning up the single node k8s setup"
        clean_setup
    fi

}

sourcef=${BASH_SOURCE[0]}
if [ $sourcef == $0 ]; then
    k8s_config $@
fi
