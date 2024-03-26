https://docs.cilium.io/en/stable/gettingstarted/demo/

# Deploy demo app

git clone https://github.com/cilium/cilium.git
cd cilium/examples/minikube/
kubectl create -f http-sw-app.yaml

# unprotected

```
[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
Ship landed
[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
Ship landed
```

# layer3 policy

 kubectl create -f sw_l3_l4_policy.yaml

# layer3 protection

```
 [ec2-user@ip-10-0-20-14 minikube]$ $ kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
-bash: $: command not found
[ec2-user@ip-10-0-20-14 minikube]$ Ship landed
-bash: Ship: command not found
[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
^C
```

# unprotected layer7 

```
[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
Panic: deathstar exploded

goroutine 1 [running]:
main.HandleGarbage(0x2080c3f50, 0x2, 0x4, 0x425c0, 0x5, 0xa)
        /code/src/github.com/empire/deathstar/
        temp/main.go:9 +0x64
main.main()
        /code/src/github.com/em
```

# layer7 policy

kubectl apply -f sw_l3_l4_l7_policy.yaml

# layer7 protection

[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
Ship landed
[ec2-user@ip-10-0-20-14 minikube]$ kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
Access denied
