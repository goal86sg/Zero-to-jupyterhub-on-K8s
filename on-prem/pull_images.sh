#!/bin/bash
cat $HOME/Zero-to-jupyterhub-on-K8s/on-prem/imagesnew.txt | xargs -I {} -- sh -c 'docker pull {}'
