# both work

kubectl exec xwing -- curl -s -XPOST deathstar.empire.svc.cluster.local/v1/request-landing

kubectl --namespace empire exec tiefighter -- curl -s -XPOST http://deathstar.empire.svc.cluster.local/v1/request-landing

# apply namespace policy

kubectl create -f namespace.yml

## doesnt work

kubectl exec xwing -- curl -s -XPOST deathstar.empire.svc.cluster.local/v1/request-landing

## works
kubectl --namespace empire exec tiefighter -- curl -s -XPOST http://deathstar.empire.svc.cluster.local/v1/request-landing

kubectl delete -f namespace.yml

# sa policy

kubectl create -f sa.yml

## doesnt work

kubectl exec xwing -- curl -s -XPOST deathstar.empire.svc.cluster.local/v1/request-landing

## works
kubectl --namespace empire exec tiefighter -- curl -s -XPOST http://deathstar.empire.svc.cluster.local/v1/request-landing

kubectl delete -f sa.yml

# label policy

kubectl create -f label.yml

## doesnt work

kubectl exec xwing -- curl -s -XPOST deathstar.empire.svc.cluster.local/v1/request-landing

## works
kubectl --namespace empire exec tiefighter -- curl -s -XPOST http://deathstar.empire.svc.cluster.local/v1/request-landing

kubectl delete -f label.yml