#!/bin/bash
USERNAME="ec2-user"
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"


# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown $USERNAME:$USERNAME "$SSH_DIR"

# Create authorized_keys file if it doesn't exist
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"
chown $USERNAME:$USERNAME "$AUTHORIZED_KEYS"

echo "THIS IS FAKE NEWS ${public_key}"
echo ${public_key} >> "$AUTHORIZED_KEYS"
cat "$AUTHORIZED_KEYS"
echo "------------------------------------------------------------------------------------------------------------"
whoami
pwd
echo "------------------------------------------------------------------------------------------------------------"
sudo yum -y update && sudo yum -y upgrade
sudo yum remove awscli -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
sudo yum install -y containerd
sudo systemctl enable containerd
sudo systemctl start containerd
sudo yum install -y nc
sudo yum install -y iproute-tc
sudo yum install -y jq
echo "runtime-endpoint: unix:///run/containerd/containerd.sock" | sudo tee /etc/crictl.yaml

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
priority=9
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet.service
sudo systemctl start kubelet.service
sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo yum install bridge-utils -y
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.ipv4.ip_forward=1
echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s-bridge.conf && sudo sysctl --system

sudo yum install git -y




