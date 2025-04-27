## jenkins and argoCD left
## https://52.3.235.120:30443/     on brave browser

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