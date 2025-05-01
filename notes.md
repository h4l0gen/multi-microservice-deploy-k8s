## jenkins and argoCD left
## https://<node_ip>>:30443/     on brave browser

cat /var/log/cloud-init-output.log

to allow ssh port 22 on ec2 instance

aws ec2 describe-instances \
  --instance-ids YOUR_INSTANCE_ID \
  --query "Reservations[].Instances[].SecurityGroups[].GroupId" \
  --output text

aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text



aws ec2 authorize-security-group-ingress \
    --group-id sg-0f3966c5891e8ede4 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0  # Allow from any IP (for testing)


aws ec2 get-console-output --instance-id i-03689a644b8a6e140


aws ec2 describe-instances --instance-ids i-03689a644b8a6e14  --query 'Reservations[0].Instances[0].State'






curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


kubectl taint nodes ip-172-31-8-54 node-role.kubernetes.io/control-plane:NoSchedule-


User (Browser / curl)
       ↓
   Istio IngressGateway (your public gateway)
       ↓
     Gateway (selects IngressGateway)
       ↓
   VirtualService (routes based on URL path)
       ↓
  Service1 / Service2 (K8s services)
       ↓
   Pods (with Envoy sidecars)


mkdir $USER_HOME/istio_certs1

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=kapilBoutique Inc./CN=kapilBoutique.com' -keyout istio_certs1/kapilBoutique.com.key -out istio_certs1/kapilBoutique.com.crt

openssl req -out istio_certs1/frontend.kapilBoutique.com.csr -newkey rsa:2048 -nodes -keyout istio_certs1/frontend.kapilBoutique.com.key -subj "/CN=frontend.kapilBoutique.com/O=frontend organization"

openssl x509 -req -sha256 -days 365 -CA istio_certs1/kapilBoutique.com.crt -CAkey istio_certs1/kapilBoutique.com.key -set_serial 0 -in istio_certs1/frontend.kapilBoutique.com.csr -out istio_certs1/frontend.kapilBoutique.com.crt

mkdir istio_certs2

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=kapilBoutique Inc./CN=kapilBoutique.com' -keyout istio_certs2/kapilBoutique.com.key -out istio_certs2/kapilBoutique.com.crt

openssl req -out istio_certs2/frontend.kapilBoutique.com.csr -newkey rsa:2048 -nodes -keyout istio_certs2/frontend.kapilBoutique.com.key -subj "/CN=frontend.kapilBoutique.com/O=frontend organization"

openssl x509 -req -sha256 -days 365 -CA istio_certs2/kapilBoutique.com.crt -CAkey istio_certs2/kapilBoutique.com.key -set_serial 0 -in istio_certs2/frontend.kapilBoutique.com.csr -out istio_certs2/frontend.kapilBoutique.com.crt





kubectl create -n istio-system secret tls frontend-credential \
  --key=istio_certs1/frontend.kapilBoutique.com.key \
  --cert=istio_certs1/frontend.kapilBoutique.com.crt


export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system

curl -v -HHost:frontend.kapilBoutique.com --resolve "frontend.kapilBoutique.com:30443:$INGRESS_HOST"   --cacert istio_certs1/kapilBoutique.com.crt "https://frontend.kapilBoutique.com:30443/status/418"



## Jenkins

git clone https://github.com/scriptcamp/kubernetes-jenkins

kubectl create namespace devops-tools

jenkins-01-serviceAccount.yaml

```
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-admin
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-admin
  namespace: devops-tools
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins-admin
subjects:
- kind: ServiceAccount
  name: jenkins-admin
  namespace: devops-tools
```

kubectl apply -f jenkins-01-serviceAccount.yaml


jenkins-02-volume.yaml

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv-volume
  labels:
    type: local
spec:
  storageClassName: local-storage
  claimRef:
    name: jenkins-pv-claim
    namespace: devops-tools
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  local:
    path: /mnt
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker-node01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pv-claim
  namespace: devops-tools
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

### Important Note: Replace 'worker-node01' with any one of your cluster worker nodes hostname. Get it by `kubectl get nodes`


kubectl create -f jenkins-02-volume.yaml

jenkins-03-deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: devops-tools
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins-server
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: jenkins-server
    spec:
      securityContext:
            # Note: fsGroup may be customized for a bit of better
            # filesystem security on the shared host
            fsGroup: 1000
            runAsUser: 1000
            ### runAsGroup: 1000
      serviceAccountName: jenkins-admin
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          # OPTIONAL: check for new floating-tag LTS releases whenever the pod is restarted:
          imagePullPolicy: Always
          resources:
            limits:
              memory: "2Gi"
              cpu: "1000m"
            requests:
              memory: "500Mi"
              cpu: "500m"
          ports:
            - name: httpport
              containerPort: 8080
            - name: jnlpport
              containerPort: 50000
          livenessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 90
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          volumeMounts:
            - name: jenkins-data
              mountPath: /var/jenkins_home
      volumes:
        - name: jenkins-data
          persistentVolumeClaim:
              claimName: jenkins-pv-claim
```




runAsUser=1000
fsGroup=1000   # Or custom ID, per above
mkdir -p /var/jenkins_home
chown -R $runAsUser:$fsGroup /var/jenkins_home
chmod -R g+rwX /var/jenkins_home


### The deployment file uses local storage class persistent volume for Jenkins data. For production use cases, you should add a cloud-specific storage class persistent volume for your Jenkins data. 

kubectl apply -f jenkins-03-deployment.yaml


jenkins-04-service.yaml
```

apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: devops-tools
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/path:   /
      prometheus.io/port:   '8080'
spec:
  selector:
    app: jenkins-server
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 32000

```

### Here, we are using the type as 'NodePort' which will expose Jenkins on all kubernetes node IPs on port 32000. If you have an ingress setup, you can create an ingress rule to access Jenkins. Also, you can expose the Jenkins service as a Loadbalancer if you are running the cluster on AWS, Google, or Azure cloud. 

kubectl apply -f jenkins-04-service.yaml

http://<node-ip>:32000

### to see jenkins server logs, Alternatively, stern tool can be used to watch multiple pods' logs.
while sleep 0.1 ; do kubectl logs -f -l app=jenkins-server -n devops-tools ; done &

