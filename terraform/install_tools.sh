#!/bin/bash
set -e

# Install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# install cri-dockerd 
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.17/cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb
apt-get install -y ./cri-dockerd_0.3.17.3-0.ubuntu-jammy_amd64.deb

# installing kubeadm, kubelet, kubectl
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

sudo kubeadm reset -f || true
sudo rm -rf /etc/kubernetes /var/lib/etcd /etc/cni/net.d || true

# Using Calico network addon here
echo "[*] Initializing kubeadm"
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock

sleep 30

USER_HOME="/home/ubuntu"
ISTIOCTL="/home/ubuntu/istio-1.25.2/bin/istioctl"
mkdir -p $USER_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $USER_HOME/.kube/config
sudo chown -R ubuntu:ubuntu $USER_HOME/.kube
sudo chmod 700 $USER_HOME/.kube
sudo chmod 600 $USER_HOME/.kube/config

# here PODs will start running

# Install calico
cd $USER_HOME
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml -O
sleep 30
kubectl apply -f calico.yaml

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm


# cloning the repository
cd $USER_HOME
git clone -b dev https://github.com/h4l0gen/multi-microservice-deploy-k8s.git


curl -L https://istio.io/downloadIstio | sh -
sudo chmod -R +x istio-*/
cd istio-*/
export PATH=$PWD/bin:$PATH
echo "export PATH=\$PATH:$PWD/bin" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc


export KUBECONFIG=$USER_HOME/.kube/config
# for istio sidecar injection
kubectl label namespace default istio-injection=enabled

# mostly problem is from here! SOLVED!!
ISTIOCTL="/home/ubuntu/istio-1.25.2/bin/istioctl"
$ISTIOCTL install -f /home/ubuntu/multi-microservice-deploy-k8s/istio-config.yaml -y

cd /home/ubuntu/multi-microservice-deploy-k8s/helm-chart
helm install kapil-server .

mkdir mkdir -p ip_certs
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

openssl req -x509 -sha256 -nodes -days 365 \
  -newkey rsa:2048 \
  -subj '/O=kapilBoutique Inc./CN=frontend' \
  -keyout ip_certs/tls.key \
  -out ip_certs/tls.crt \
  -addext "subjectAltName = IP:$NODE_IP"

kubectl create -n istio-system secret tls ip-credential \
  --key=ip_certs/tls.key \
  --cert=ip_certs/tls.crt