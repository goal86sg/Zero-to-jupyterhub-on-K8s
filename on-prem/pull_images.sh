#!/bin/bash
cat $HOME/Zero-to-jupyterhub-on-K8s/on-prem/images.txt | xargs -I {} -- sh -c 'docker pull {}'
