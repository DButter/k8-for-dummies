kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/tigera-operator.yaml
curl -s https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/custom-resources.yaml | sed 's|cidr: 192.168.0.0/16|cidr: ${pod_network_cidr}|' | kubectl create -f -

sudo curl -L https://github.com/projectcalico/calico/releases/download/${calico_version}/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
