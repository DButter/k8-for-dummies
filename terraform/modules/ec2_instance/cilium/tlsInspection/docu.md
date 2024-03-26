https://docs.cilium.io/en/stable/security/tls-visibility/

# Deploy demo app

git clone https://github.com/cilium/cilium.git
cd cilium/examples/kubernetes-dns/
kubectl create -f dns-sw-app.yaml

# create app cert and sign it with cluster cert

openssl genrsa -out internal-artii.key 2048


openssl.cnf
```
[ req ]
default_bits        = 4096
prompt              = no
default_md          = sha256
distinguished_name  = req_distinguished_name
req_extensions      = req_ext

[ req_distinguished_name ]
CN = artii.herokuapp.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = artii.herokuapp.com

```

openssl req -new -key internal-artii.key -out internal-artii.csr -config openssl.cnf
openssl x509 -req -days 360 -in internal-artii.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out internal-artii.crt -sha256

## create secret 
kubectl create secret tls artii-tls-data -n kube-system --cert=internal-artii.crt --key=internal-artii.key
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=kube-system:cilium
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets --namespace=kube-system
kubectl create rolebinding default-to-secrets --role=access-secrets --serviceaccount=kube-system:cilium --namespace=kube-system


## make mediabot trust my ca

kubectl cp /etc/kubernetes/pki/ca.crt default/mediabot:/usr/local/share/ca-certificates/myCA.crt
kubectl exec mediabot -- update-ca-certificates

kubectl create secret generic tls-orig-data -n kube-system --from-file=/etc/kubernetes/pki/ca.crt=./ca-certificates.crt

kubectl cp default/mediabot:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt
kubectl create secret generic tls-orig-data -n kube-system --from-file=ca.crt=./ca-certificates.crt

kubectl create -f ../kubernetes-tls-inspection/l7-visibility-tls.yaml

# observe

```
[ec2-user@ip-10-0-20-14 ~]$ cilium hubble port-forward&
[1] 2240
[ec2-user@ip-10-0-20-14 ~]$ hubble status
Healthcheck (via localhost:4245): Ok
Current/Max Flows: 24,570/24,570 (100.00%)
Flows/s: 37.26
Connected Nodes: 6/6
[ec2-user@ip-10-0-20-14 ~]$ hubble observe -f -t l7 -o compact
Mar 22 15:26:02.080: default/mediabot:40094 (ID:11871) -> artii.herokuapp.com:443 (ID:16777220) http-request FORWARDED (HTTP/1.1 GET https://artii.herokuapp.com/fonts_list)
Mar 22 15:26:02.111: default/mediabot:40094 (ID:11871) <- artii.herokuapp.com:443 (ID:16777220) http-response FORWARDED (HTTP/1.1 404 124ms (GET https://artii.herokuapp.com/fonts_list))
```