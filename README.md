# test-longhorn

# 想定する構成
- longhornの上にminio構築
- longhornのバックアップ先はnfs

# 構築手順

## インストール

```bash
$ helm repo add longhorn https://charts.longhorn.io
$ helm repo update
$ helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.7.2
```

```bash
$ kubectl -n longhorn-system get pod
NAME                                                READY   STATUS    RESTARTS   AGE
csi-attacher-698944d5b-btzcf                        1/1     Running   0          77s
csi-attacher-698944d5b-fgjlb                        1/1     Running   0          77s
csi-attacher-698944d5b-h8tf9                        1/1     Running   0          77s
csi-provisioner-b98c99578-dcwnp                     1/1     Running   0          77s
csi-provisioner-b98c99578-s9r7x                     1/1     Running   0          77s
csi-provisioner-b98c99578-v88bc                     1/1     Running   0          77s
csi-resizer-7474b7b598-8ndbt                        1/1     Running   0          77s
csi-resizer-7474b7b598-ncqkc                        1/1     Running   0          77s
csi-resizer-7474b7b598-t5llb                        1/1     Running   0          77s
csi-snapshotter-774467fdc7-2dqh2                    1/1     Running   0          77s
csi-snapshotter-774467fdc7-7rwgd                    1/1     Running   0          77s
csi-snapshotter-774467fdc7-9qsd6                    1/1     Running   0          77s
engine-image-ei-51cc7b9c-4bzsv                      1/1     Running   0          2m9s
engine-image-ei-51cc7b9c-fqsk5                      1/1     Running   0          2m9s
engine-image-ei-51cc7b9c-vbdxg                      1/1     Running   0          2m9s
instance-manager-8311fc54b0bd3e215f482dd0ac1023c9   1/1     Running   0          98s
instance-manager-c6322749fe03c4995aa7bc75d434d095   1/1     Running   0          98s
instance-manager-e7d070f64f4ce17a52f2e5865f4d31d3   1/1     Running   0          98s
longhorn-csi-plugin-fl6v2                           3/3     Running   0          77s
longhorn-csi-plugin-hfbw8                           3/3     Running   0          77s
longhorn-csi-plugin-tcd6q                           3/3     Running   0          77s
longhorn-driver-deployer-7d77d779dd-bbl2r           1/1     Running   0          2m30s
longhorn-manager-2ngdp                              2/2     Running   0          2m30s
longhorn-manager-rdnqf                              2/2     Running   0          2m30s
longhorn-manager-s2kbj                              2/2     Running   0          2m30s
longhorn-ui-7c784d8587-dzdqz                        1/1     Running   0          2m30s
longhorn-ui-7c784d8587-kv9c6                        1/1     Running   0          2m30s
```

## UIアクセス
```bash
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
```

> http://192.168.11.161:8087

## クリーンアップ
```bash
kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
helm uninstall longhorn -n longhorn-system
kubectl delete namespace longhorn-system
```
