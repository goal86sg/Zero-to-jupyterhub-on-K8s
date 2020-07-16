#!/bin/bash
echo "Enter your private registry URL"
read PRIVATE_REGISTRY
cat $HOME/Zero-to-jupyterhub-on-K8s/on-prem/images.txt | xargs -I {} -- sh -c 'docker tag {} '"$PRIVATE_REGISTRY"'/{} && docker push '"$PRIVATE_REGISTRY"'/{}'
