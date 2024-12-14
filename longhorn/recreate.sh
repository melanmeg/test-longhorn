#!/bin/bash

kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag && \
  helm uninstall longhorn -n longhorn-system && \
  kubectl delete namespace longhorn-system

helm repo add longhorn https://charts.longhorn.io

helm install longhorn longhorn/longhorn \
--namespace longhorn-system \
--create-namespace \
--version 1.7.2 \
--values values.yaml

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: longhorn-ui
  namespace: longhorn-system
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: http
      nodePort: 30007
      protocol: TCP
  selector:
    app: longhorn-ui
EOF
