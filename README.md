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
NAMESPACE            NAME                                              READY   STATUS    RESTARTS   AGE
container-registry   registry-7cf58dcdcc-hps4t                         1/1     Running   4          170m
kube-system          coredns-588fd544bf-649gb                          1/1     Running   5          170m
kube-system          dashboard-metrics-scraper-db65b9c6f-7f7bt         1/1     Running   6          170m
kube-system          heapster-v1.5.2-58fdbb6f4d-qvdpv                  4/4     Running   20         170m
kube-system          hostpath-provisioner-75fdc8fccd-wlfcn             1/1     Running   5          170m
kube-system          kubernetes-dashboard-67765b55f5-pjhq4             1/1     Running   5          170m
kube-system          monitoring-influxdb-grafana-v4-6dc675bf8c-nvvhz   2/2     Running   8          170m
metallb-system       controller-5f98465b6b-rfbjl                       1/1     Running   5          170m
metallb-system       speaker-4926w                                     1/1     Running   6          170m
metallb-system       speaker-r9zsl                                     1/1     Running   0          157m
jhub                 continuous-image-puller-8fxvm                     1/1     Running   0          52m
jhub                 continuous-image-puller-q86td                     1/1     Running   0          52m
jhub                 hub-57567b69c7-vrwpt                              1/1     Running   2          52m
jhub                 jupyter-admin                                     1/1     Running   0          47m
jhub                 proxy-747cffc6db-8rql9                            1/1     Running   0          52m
jhub                 user-scheduler-fdddf9b65-t9msx                    1/1     Running   0          52m
jhub                 user-scheduler-fdddf9b65-zcftr                    1/1     Running   0          52m
```
```
NAMESPACE            NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
container-registry   registry                    NodePort       10.152.183.102   <none>         5000:32000/TCP               172m
default              kubernetes                  ClusterIP      10.152.183.1     <none>         443/TCP                      3h14m
kube-system          dashboard-metrics-scraper   ClusterIP      10.152.183.244   <none>         8000/TCP                     172m
kube-system          heapster                    ClusterIP      10.152.183.117   <none>         80/TCP                       172m
kube-system          kube-dns                    ClusterIP      10.152.183.10    <none>         53/UDP,53/TCP,9153/TCP       172m
kube-system          kubernetes-dashboard        ClusterIP      10.152.183.176   <none>         443/TCP                      172m
kube-system          monitoring-grafana          ClusterIP      10.152.183.78    <none>         80/TCP                       172m
kube-system          monitoring-influxdb         ClusterIP      10.152.183.9     <none>         8083/TCP,8086/TCP            172m
jhub                 hub                         ClusterIP      10.152.183.122   <none>         8081/TCP                     54m
jhub                 proxy-api                   ClusterIP      10.152.183.73    <none>         8001/TCP                     54m
jhub                 proxy-public                LoadBalancer   10.152.183.184   10.64.140.43   443:31727/TCP,80:32393/TCP   54m
```

## Jupyterhub front end
```
Access via the metallb external ip or via the node port ip http://xx.xx.xx.xx:32393
```

## Applying Config changes
```
RELEASE=jhub
helm upgrade $RELEASE jupyterhub/jupyterhub \
  --version=0.9.0 \
  --values config.yaml
```
