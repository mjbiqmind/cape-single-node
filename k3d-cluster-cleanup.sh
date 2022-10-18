#!/bin/bash

k3d registry delete docker-io
k3d cluster delete saas
k3d cluster delete eks-demo
k3d cluster delete aks-demo
k3d cluster delete k3s-demo
k3d cluster delete eks-smoketest
k3d cluster delete aks-smoketest