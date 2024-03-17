# application policy
# https://docs.tigera.io/calico/latest/network-policy/get-started/calico-policy/calico-policy-tutorial

# deploy nginx

kubectl create ns advanced-policy-demo
kubectl create deployment --namespace=advanced-policy-demo nginx --image=nginx
kubectl expose --namespace=advanced-policy-demo deployment nginx --port=80

# deploy busybox and shell into it

kubectl run --namespace=advanced-policy-demo access --rm -ti --image busybox /bin/sh

# confirm connectivity internal
wget -q --timeout=5 nginx -O -
# external
wget -q --timeout=5 google.com -O -
# lockdown
calicoctl create -f lockdown.yaml

```
[ec2-user@ip-10-0-27-77 ~]$ kubectl run --namespace=advanced-policy-demo access --rm -ti --image busybox /bin/sh
If you don't see a command prompt, try pressing enter.
/ #
/ # wget -q --timeout=5 nginx -O -
wget: bad address 'nginx'
/ # wget -q --timeout=5 google.com -O -
wget: bad address 'google.com'
/ #
```
 calicoctl create -f externalAccess.yaml
```
 / # wget -q --timeout=5 nginx -O -
wget: download timed out
/ # wget -q --timeout=5 google.com -O -
<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" 
```

calicoctl create -f internalAccess.yaml
```
/ # wget -q --timeout=5 nginx -O -
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
/ # wget -q --timeout=5 google.com -O -
<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage"
```

# cleanup

calicoctl delete policy allow-busybox-egress -n advanced-policy-demo
calicoctl delete policy allow-nginx-ingress -n advanced-policy-demo
calicoctl delete gnp default-deny
kubectl delete ns advanced-policy-demo