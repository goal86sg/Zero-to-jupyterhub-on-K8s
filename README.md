# Zero-to-jupyterhub-on-K8s

## Enable Microk8s
```
export microk8s_version=1.18/stable

sudo echo # This prevents sudo from asking you for a password later
sudo apt -y update && sudo apt -y upgrade
sudo snap install microk8s --classic --channel=${microk8s_version}
sudo usermod -a -G microk8s $USER
exit # exit shall to let permissions take effect

microk8s.status --wait-ready
microk8s.enable dns dashboard storage registry mettallb
# note storage default mount point is 10GB and is mounted on local filesystem /var/snap/microk8s/common/default-storage

# Alias microk8s.kubectl to kubectl
alias kubectl='microk8s.kubectl'

# Also add microk8s to local kubeconfig so helm can use the config
microk8s.kubectl config view --raw >> ~/.kube/config
```

## Allow Priviledged in Kube-api server
```
sudo echo"--allow-priviledged=true" >> /var/snap/microk8s/current/args/kube-apiserver
microk8s.stop&&microk8.start
```

## Install latest Helm
```
export helm_version=3.1.1
echo "Installing 'helm' v${helm_version}" \
&&   sudo wget -c https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz \
&&   sudo tar -zxvf helm-v${helm_version}-linux-amd64.tar.gz \
&&   sudo chmod 0755 ./linux-amd64/helm \
&&   sudo mv ./linux-amd64/helm /usr/local/bin/helm \
&&   sudo rm -rf helm-v${helm_version}-linux-amd64.tar.gz ./linux-amd64/ \
&&   helm version
```

## Generate a random hex string representing 32 bytes to use as a security token
```
openssl rand -hex 32
```

## Create a config.yaml enter the random HEX into this file
```
sudo tee -a config.yaml > /dev/null <<EOT
proxy:
  secretToken: "<RANDOM_HEX>"
EOT
```

## Install JupyterHub with Helm
```
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
kubectl create namespace jhub
RELEASE=jhub
NAMESPACE=jhub

helm upgrade --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE  \
  --version=0.9.0 \
  --values config.yaml
```

## Deployed Jupyterhub on Kubernetes
```

```
