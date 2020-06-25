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
microk8s.enable dns dashboard storage registry metallb
# note storage default mount point is 10GB and is mounted on local filesystem /var/snap/microk8s/common/default-storage

# Alias microk8s.kubectl to kubectl
alias kubectl='microk8s.kubectl'

# Also add microk8s to local kubeconfig so helm can use the config
microk8s.kubectl config view --raw >> ~/.kube/config

#Only enable gpu once nvidia GPU driver is installed
microk8s.enable gpu
```

## Allow Priviledged in Kube-api server
```
sudo echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver
microk8s.stop
sleep 20
microk8s.start
```

## Install latest Helm
```
export helm_version=3.2.4
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

## Install or Reconfiguring JupyterHub with Helm
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


## Offline Setup of JupyterHub
```
Repeat steps with internet connection first
-Enable Microk8s
-Allow Priviledged in Kube-api server
-Install latest Helm
```

#### Install docker and docker-compose
```
sudo echo # This prevents sudo from asking you for a password later
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group so you don't need to sudo 
sudo usermod -aG docker $USER
# exit shell for changes to take effect

echo "Installing 'docker-compose' v${docker_compose_version}" \
&&   sudo wget -cO /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m) \
&&   sudo chmod 0755 /usr/local/bin/docker-compose \
&&   docker-compose --version
```

#### Get JupyterHub Helm Bundle
```
export helm_version=0.9.0
version
wget https://jupyterhub.github.io/helm-chart/jupyterhub-v${helm_version}.tgz
tar -zxvf jupyterhub-v${helm_version}.tgz
```

### Pull tag push docker images required to microk8s registry
```
REPOSITORY                                                      TAG                 IMAGE ID            CREATED             SIZE
cschranz/gpu-jupyter                                            latest              8b805e56e4c4        45 hours ago        14.4GB
gcr.io/google_containers/kube-scheduler-amd64                   v1.13.12            54f3185a42a5        8 months ago        79.6MB
gcr.io/google_containers/pause                                  3.1                 da86e6ba6ca1        2 years ago         742kB
jupyter/all-spark-notebook                                      2343e33dec46        708afc986779        18 months ago       6.32GB
jupyter/datascience-notebook                                    2343e33dec46        60b2ad31b985        18 months ago       6.33GB
jupyterhub/configurable-http-proxy                              4.2.1               3379bc93b897        3 months ago        138MB
jupyterhub/k8s-hub                                              0.9.0               2f82dac5c3ab        2 months ago        632MB
jupyterhub/k8s-image-awaiter                                    0.9.0               7b10713c8231        2 months ago        4.15MB
jupyterhub/k8s-network-tools                                    0.9.0               00c5e7b520c2        2 months ago        5.62MB
jupyterhub/k8s-secret-sync                                      0.9.0               be42ccae8a88        2 months ago        132MB
jupyterhub/k8s-singleuser-sample                                0.9.0               854de563978d        2 months ago        676MB
jupyter/minimal-notebook                                        2343e33dec46        c3bbd3471e39        18 months ago       2.72GB
jupyter/pyspark-notebook                                        dd2087c75645        96dae139b62b        9 days ago          4.21GB
jupyter/scipy-notebook                                          dd2087c75645        376a7f2eca8e        9 days ago          3.41GB
jupyter/tensorflow-notebook                                     dd2087c75645        388aa83f6d09        9 days ago          4.98GB
localhost:32000/cschranz/gpu-jupyter                            latest              8b805e56e4c4        45 hours ago        14.4GB
localhost:32000/gcr.io/google_containers/kube-scheduler-amd64   v1.13.12            54f3185a42a5        8 months ago        79.6MB
localhost:32000/gcr.io/google_containers/pause                  3.1                 da86e6ba6ca1        2 years ago         742kB
localhost:32000/jupyter/all-spark-notebook                      2343e33dec46        708afc986779        18 months ago       6.32GB
localhost:32000/jupyter/datascience-notebook                    2343e33dec46        60b2ad31b985        18 months ago       6.33GB
localhost:32000/jupyterhub/configurable-http-proxy              4.2.1               3379bc93b897        3 months ago        138MB
localhost:32000/jupyterhub/k8s-hub                              0.9.0               2f82dac5c3ab        2 months ago        632MB
localhost:32000/jupyterhub/k8s-image-awaiter                    0.9.0               7b10713c8231        2 months ago        4.15MB
localhost:32000/jupyterhub/k8s-network-tools                    0.9.0               00c5e7b520c2        2 months ago        5.62MB
localhost:32000/jupyterhub/k8s-secret-sync                      0.9.0               be42ccae8a88        2 months ago        132MB
localhost:32000/jupyterhub/k8s-singleuser-sample                0.9.0               854de563978d        2 months ago        676MB
localhost:32000/jupyter/minimal-notebook                        2343e33dec46        c3bbd3471e39        18 months ago       2.72GB
localhost:32000/jupyter/pyspark-notebook                        dd2087c75645        96dae139b62b        9 days ago          4.21GB
localhost:32000/jupyter/scipy-notebook                          dd2087c75645        376a7f2eca8e        9 days ago          3.41GB
localhost:32000/jupyter/tensorflow-notebook                     dd2087c75645        388aa83f6d09        9 days ago          4.98GB
localhost:32000/traefik                                         v2.1                72bfc37343a4        3 months ago        68.9MB
traefik                                                         v2.1                72bfc37343a4        3 months ago        68.9MB

microk8s ctr images ls
```

### Prepare VM template
```
Shutdown
Export VM as template
Import in airgap network
Import VM template
Power up
Change IP
```

### Deploy Jupyterhub offline Helm chart
```
RELEASE=jhub
NAMESPACE=jhub
helm install $RELEASE ./jupyterhub --version=0.9.0 --values config.yaml
or
helm upgrade --install jhub jupyterhub/jupyterhub   --namespace jhub    --version=0.9.0   --values config.yaml
```
