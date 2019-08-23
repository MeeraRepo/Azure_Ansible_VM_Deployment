#!/bin/bash
az aks get-credentials --resource-group aksansibletest --name aksansibletest
kubectl get nodes
kubectl get pods -n kube-system
git clone https://github.com/Azure/kubernetes-hackfest.git
cd kubernetes-hackfest
cd kubernetes-hackfest/labs/monitoring-logging/prometheus-grafana/
kubectl apply -f prom-rbactillerconfig.yaml
helm init
sleep 30
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
helm install coreos/prometheus-operator --version 0.0.27 --name prometheus-operator --namespace kube-system
kubectl -n kube-system get all -l "release=prometheus-operator"
helm install coreos/kube-prometheus --version 0.0.95 --name kube-prometheus --namespace kube-system