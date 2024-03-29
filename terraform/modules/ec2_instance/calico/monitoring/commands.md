# activate metrics

kubectl patch felixconfiguration default --type merge --patch '{"spec":{"prometheusMetricsEnabled": true}}'
kubectl patch kubecontrollersconfiguration default --type=merge  --patch '{"spec":{"prometheusMetricsPort": 9095}}'

# activate typha

kubectl patch installation default --type=merge -p '{"spec": {"typhaMetricsPort":9093}}'

# create k8 resources

kubectl apply -f prometheus.yml

# forward prometheus

ssh -L 1234:127.0.0.1:9090 -J ec2-user@3.75.196.11 ec2-user@10.0.30.236 -N -A -v


# grafana

kubectl apply -f grafana_0.yml

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/grafana-dashboards.yaml

kubectl apply -f grafana_1.yml

ssh -L 1234:127.0.0.1:3000 -J ec2-user@3.75.196.11 ec2-user@10.0.30.236 -N -A -v