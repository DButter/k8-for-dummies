https://docs.cilium.io/en/stable/observability/grafana/
https://github.com/cilium/cilium/blob/main/examples/kubernetes/addons/prometheus/README.md

# activate metrics



kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.15.3/examples/kubernetes/addons/prometheus/monitoring-example.yaml

cilium hubble enable --ui

# grafana

kubectl -n cilium-monitoring port-forward service/grafana --address 0.0.0.0 --address :: 3000:3000
ssh -L 1234:127.0.0.1:3000 -J ec2-user@3.71.185.221 ec2-user@10.0.30.109 -N -A -v

# prometheus
kubectl -n cilium-monitoring port-forward service/prometheus --address 0.0.0.0 --address :: 9090:9090
ssh -L 5678:127.0.0.1:9090 -J ec2-user@3.71.185.221 ec2-user@10.0.27.4 -N -A -v

# hubble

cilium hubble ui --open-browser=false
ssh -L 9101:127.0.0.1:12000 -J ec2-user@3.71.185.221 ec2-user@10.0.30.109 -N -A -v