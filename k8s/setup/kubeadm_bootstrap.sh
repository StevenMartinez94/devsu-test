#!/bin/bash
set -e

NEW_HOSTNAME="$1"
IS_MASTER=false

if [[ "$NEW_HOSTNAME" == "masternode" ]]; then
  IS_MASTER=true
fi

sudo apt update && sudo apt install neofetch jq curl wget bpytop tree neovim -y

# Create ubuntu user if it doesn't exist, without password and with sudo permissions
if ! id "ubuntu" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" ubuntu
fi

# Add to sudo group
sudo usermod -aG sudo ubuntu

# Disable password so login is only via SSH key
sudo passwd -d ubuntu

# Disable swap
swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Set sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install containerd
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io -y

# Configure containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Install Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


# Initialize Kubernetes cluster
if [[ "$IS_MASTER" == true ]]; then
  echo "[INFO] Initializing Kubernetes master node..."
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.32.7

  # Correct kubeconfig setup for the 'ubuntu' user
  sudo mkdir -p /home/ubuntu/.kube
  sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

  # Use correct kubeconfig
  export KUBECONFIG=/home/ubuntu/.kube/config

  # Wait for API server
  echo "[INFO] Waiting for kube-apiserver to become responsive..."
  for i in {1..20}; do
    if kubectl get --raw=/healthz &>/dev/null; then
      echo "[INFO] kube-apiserver is up."
      break
    fi
    echo "[$i/20] Waiting for API server..."
    sleep 5
  done

  # Apply Flannel CNI
  echo "[INFO] Applying Flannel CNI..."
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --validate=false

  # Wait for Flannel DaemonSet pods to be ready in kube-system
  echo "[INFO] Waiting for Flannel pods to be ready..."
  for i in {1..20}; do
    READY=$(kubectl get pods -n kube-system -l app=flannel -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>/dev/null)
    if [[ "$READY" == "true" ]]; then
      echo "[INFO] Flannel pod is Running and Ready."
      break
    fi
    echo "[$i/20] Flannel pod not ready yet. Waiting..."
    sleep 5
  done

  # Enable bridge networking for Kubernetes
  sudo modprobe br_netfilter
  echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
  echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.d/k8s.conf
  echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.d/k8s.conf
  sudo sysctl --system

  # Restart kubelet and containerd to ensure everything picks up config
  sudo systemctl restart kubelet
  sudo systemctl restart containerd

  echo "[INFO] Kubernetes cluster initialized."
fi
