# test-longhorn

# 構築手順

## ディスクの用意
- 前提として、各ワーカーノードの/dev/vdbにrawディスクが用意されている

```bash
$ sudo mkfs.xfs /dev/vdb
$ sudo mkdir -p /mnt/longhorn-xfs
$ sudo mount /dev/vdb /mnt/longhorn-xfs
$ echo "/dev/vdb /mnt/longhorn-xfs xfs defaults 0 0" | sudo tee -a /etc/fstab
```

## インストール
```bash
$ helm repo add longhorn https://charts.longhorn.io && \
  helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.7.2 \
  --values values.yaml
```

```bash
$ kubectl -n longhorn-system get pod
NAME                                                READY   STATUS    RESTARTS   AGE
csi-attacher-59d7469cbc-jp8ch                       1/1     Running   0          28s
csi-attacher-59d7469cbc-q67vw                       1/1     Running   0          28s
csi-attacher-59d7469cbc-q7bxj                       1/1     Running   0          28s
csi-provisioner-7c96bfb54f-dbkp8                    1/1     Running   0          28s
csi-provisioner-7c96bfb54f-qx2r2                    1/1     Running   0          28s
csi-provisioner-7c96bfb54f-w75bd                    1/1     Running   0          28s
csi-resizer-6d6b8476df-4487v                        1/1     Running   0          28s
csi-resizer-6d6b8476df-rbpdb                        1/1     Running   0          28s
csi-resizer-6d6b8476df-rbvbz                        1/1     Running   0          28s
csi-snapshotter-75958cbd5b-g6mxp                    1/1     Running   0          28s
csi-snapshotter-75958cbd5b-w7nmp                    1/1     Running   0          28s
csi-snapshotter-75958cbd5b-x87qt                    1/1     Running   0          28s
engine-image-ei-51cc7b9c-9qfht                      1/1     Running   0          31s
engine-image-ei-51cc7b9c-ggt8d                      1/1     Running   0          31s
engine-image-ei-51cc7b9c-sw76w                      1/1     Running   0          31s
instance-manager-8311fc54b0bd3e215f482dd0ac1023c9   1/1     Running   0          30s
instance-manager-c6322749fe03c4995aa7bc75d434d095   1/1     Running   0          31s
instance-manager-e7d070f64f4ce17a52f2e5865f4d31d3   1/1     Running   0          31s
longhorn-csi-plugin-cwxjb                           3/3     Running   0          28s
longhorn-csi-plugin-fkpgt                           3/3     Running   0          28s
longhorn-csi-plugin-hvbkw                           3/3     Running   0          28s
longhorn-driver-deployer-7d77d779dd-ch8q8           1/1     Running   0          38s
longhorn-manager-7dnq7                              2/2     Running   0          38s
longhorn-manager-nmwb9                              2/2     Running   0          38s
longhorn-manager-vr6p5                              2/2     Running   0          38s
longhorn-ui-7c784d8587-8v69p                        1/1     Running   0          38s
longhorn-ui-7c784d8587-kvndq                        1/1     Running   0          38s
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

## ストレージタグ
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: storageclass-config
  namespace: longhorn-system
data:
  storageclass.yaml: |
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
        node.longhorn.io/default-node-tags: '["fast","storage"]'
        node.longhorn.io/create-default-disk: 'config'
        node.longhorn.io/default-disks-config:
        '[
            {
                "name":"fast-ssd-disk",
                "path":"/mnt/longhorn-xfs",
                "allowScheduling":false,
                "storageReserved":10485760,
                "tags":[
                    "ssd",
                    "fast"
                ]
            }
        ]'
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    reclaimPolicy: "Delete"
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "3"
      staleReplicaTimeout: "480"
      diskSelector: "ssd"
      nodeSelector: "storage,fast"
EOF
```

```bash
kubectl apply -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-fast
  namespace: longhorn-system
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "480" # 8 hours in minutes
  diskSelector: "ssd"
  nodeSelector: "storage,fast"
EOF
```


## ノードとディスクのデフォルト設定
```bash
```

## クリーンアップ
```bash
$ kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag && \
  helm uninstall longhorn -n longhorn-system && \
  kubectl delete namespace longhorn-system
```

Helmを使用してロングホーンをインストールする場合は、
チャートをインストールする前にvalues.yamlファイルで
global.nodeSelector、longhornManager.nodeSelector、longhornUI.nodeSelector、longhornDriver.nodeSelector
のHelm値を変更できます。
